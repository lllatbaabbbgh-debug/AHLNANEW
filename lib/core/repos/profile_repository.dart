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
    final c = _c;
    if (c == null) {
      debugPrint('ProfileRepository: Supabase client is null');
      return false;
    }
    
    try {
      // محاولة الإدراج/التحديث باستخدام عميل المصادقة العادي
      debugPrint('ProfileRepository: Attempting upsert with auth client for phone: $phone, user: ${user ?? phone}');
      await c.from(table).upsert({
        'phone': phone,
        'name': name,
        'address': address,
        'user': user ?? phone,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'phone');
      debugPrint('ProfileRepository: Upsert successful with auth client');
          return true;
        } catch (e) {
          debugPrint('ProfileRepository: Auth client upsert failed: $e');
          
          final svc = SupabaseManager.serviceClient;
          if (svc != null) {
            try {
              debugPrint('ProfileRepository: Attempting upsert with service client');
              await svc.from(table).upsert({
                'phone': phone,
                'name': name,
                'address': address,
                'user': user ?? phone,
                'updated_at': DateTime.now().toIso8601String(),
              }, onConflict: 'phone');
              debugPrint('ProfileRepository: Upsert successful with service client');
              return true;
            } catch (svcError) {
              debugPrint('ProfileRepository: Service client upsert also failed: $svcError');
            }
          } else {
            debugPrint('ProfileRepository: Service client is null');
          }
        }
        
        debugPrint('ProfileRepository: All upsert attempts failed');
        return false;
  }

  Future<Map<String, dynamic>?> getByPhone(String phone) async {
    final c = _c;
    if (c == null) return null;
    final res = await c.from(table).select().eq('phone', phone).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>?> getByUser(String userId) async {
    final c = _c;
    if (c == null) return null;
    final res = await c.from(table).select().eq('user', userId).maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<void> delete(String phone) async {
    final c = _c;
    if (c == null) return;

    try {
      // محاولة الحذف النهائي
      // نستخدم select() للتأكد من تنفيذ الحذف واسترجاع ما تم حذفه
      final List<dynamic> data = await c
          .from(table)
          .delete()
          .eq('phone', phone)
          .select();

      // إذا لم يتم حذف أي سجل (بسبب سياسات الأمان RLS أو عدم وجود السجل)
      if (data.isEmpty) {
        // نقوم "بتصفير" البيانات كحل بديل لضمان اختفاء معلومات المستخدم
        await c
            .from(table)
            .update({
              'name': '',
              'address': '',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('phone', phone);
      }
    } catch (e) {
      // في حال حدوث خطأ غير متوقع، نحاول تصفير البيانات أيضاً
      try {
        await c
            .from(table)
            .update({'name': '', 'address': ''})
            .eq('phone', phone);
      } catch (_) {}
    }
  }
}
