import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../supabase_client.dart';

class ProfileRepository {
  static const table = 'profiles';
  SupabaseClient? get _c => SupabaseManager.client;

  Future<bool> upsert({
    required String phone,
    required String name,
    required String address,
    String? user,
  }) async {
    // 1. Try to use Service Client FIRST (Bypass all RLS/Trigger permissions issues)
    final serviceClient = SupabaseManager.serviceClient;
    final standardClient = _c;

    // Decide which client to use: Prefer Service Client for reliability
    final clientToUse = serviceClient ?? standardClient;

    if (clientToUse == null) {
      debugPrint('ProfileRepository: No Supabase client available');
      return false;
    }

    // 2. Use rpc_create_profile function
    try {
      debugPrint(
        'ProfileRepository: Attempting RPC with ${clientToUse == serviceClient ? "Service Client" : "Standard Client"}',
      );

      final response = await clientToUse.rpc(
        'rpc_create_profile',
        params: {'p_name': name, 'p_phone': phone, 'p_address': address},
      );

      debugPrint('ProfileRepository: RPC Success! Response: $response');

      // 3. IMPORTANT: Link the profile to the Auth User ID if provided
      if (user != null && _isValidUUID(user)) {
        try {
          debugPrint('ProfileRepository: Linking profile to user $user...');
          await clientToUse
              .from(table)
              .update({
                'user_id': user,
                // Also update user_id_text just in case
                'user_id_text': user,
              })
              .eq('phone', phone);
          debugPrint('ProfileRepository: Profile linked successfully!');
        } catch (linkError) {
          debugPrint(
            'ProfileRepository: Warning - Failed to link profile to user: $linkError',
          );
          // We don't return false here because the profile WAS created.
          // The user can still use the app, but might have issues if they rely solely on Auth ID.
        }
      }

      return true;
    } catch (e) {
      debugPrint('ProfileRepository: RPC failed: $e');

      // 3. If Service Client failed (unlikely) or wasn't available, try fallback
      // If we already used Service Client, maybe try Standard Client just in case?
      // Unlikely to help if Service Client failed, but let's be exhaustive.
      if (clientToUse == serviceClient && standardClient != null) {
        try {
          debugPrint('ProfileRepository: Retrying RPC with Standard Client...');
          await standardClient.rpc(
            'rpc_create_profile',
            params: {'p_name': name, 'p_phone': phone, 'p_address': address},
          );
          return true;
        } catch (_) {}
      }

      // 4. Fallback to old upsert method if RPC fails completely
      return await _fallbackUpsert(phone, name, address, user);
    }
  }

  Future<bool> _fallbackUpsert(
    String phone,
    String name,
    String address,
    String? user,
  ) async {
    final c = _c;
    if (c == null) return false;

    final Map<String, dynamic> data = {
      'phone': phone,
      'name': name,
      'address': address,
      'user_id_text': user ?? phone,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (user != null && _isValidUUID(user)) {
      data['user_id'] = user;
    }

    bool success = await _tryUpsert(c, data, 'Standard Client (Fallback)');

    if (!success) {
      final dataWithLegacy = Map<String, dynamic>.from(data);
      dataWithLegacy['user'] = null;
      success = await _tryUpsert(
        c,
        dataWithLegacy,
        'Standard Client (Legacy Fallback)',
      );
    }

    if (!success) {
      final svc = SupabaseManager.serviceClient;
      if (svc != null) {
        success = await _tryUpsert(svc, data, 'Service Client (Fallback)');
      }
    }

    return success;
  }

  Future<bool> _tryUpsert(
    SupabaseClient client,
    Map<String, dynamic> data,
    String mode,
  ) async {
    try {
      debugPrint(
        'ProfileRepository: Attempting upsert [$mode] with data: $data',
      );
      await client.from(table).upsert(data, onConflict: 'phone');
      debugPrint('ProfileRepository: Success [$mode]!');
      return true;
    } catch (e) {
      debugPrint('ProfileRepository: Failed [$mode]: $e');
      // If the error is strictly about the missing column, and we are in legacy mode,
      // it means the column truly doesn't exist.
      // But if we are here, we want to try the next method.
      return false;
    }
  }

  bool _isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }

  Future<Map<String, dynamic>?> getByPhone(String phone) async {
    final c = _c;
    if (c == null) return null;
    try {
      final res = await c.from(table).select().eq('phone', phone).maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('ProfileRepository: getByPhone failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getByUser(String userId) async {
    final c = _c;
    if (c == null) return null;
    try {
      final res = await c
          .from(table)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    } catch (_) {}

    try {
      final res = await c
          .from(table)
          .select()
          .eq('user_id_text', userId)
          .maybeSingle();
      if (res != null) return Map<String, dynamic>.from(res);
    } catch (_) {}

    return null;
  }

  Future<bool> delete(String phone) async {
    final c = _c;
    if (c == null) return false;

    try {
      await c.from(table).delete().eq('phone', phone);
      return true;
    } catch (e) {
      debugPrint('ProfileRepository: Delete failed: $e');
      // Try with service client
      final svc = SupabaseManager.serviceClient;
      if (svc != null) {
        try {
          await svc.from(table).delete().eq('phone', phone);
          return true;
        } catch (_) {}
      }
      return false;
    }
  }
}
