import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class ProfileRepository {
  static const table = 'profiles';
  SupabaseClient? get _c => SupabaseManager.client;

  Future<void> upsert({required String phone, required String name, required String address, String? user}) async {
    final c = _c;
    if (c == null) return;
    await c.from(table).upsert({
      'phone': phone,
      'name': name,
      'address': address,
      'user': user ?? phone,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'phone');
  }

  Future<Map<String, dynamic>?> getByPhone(String phone) async {
    final c = _c;
    if (c == null) return null;
    final res = await c.from(table).select().eq('phone', phone).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }
}
