import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class ProfileRepository {
  static const table = 'profiles';
  SupabaseClient? get _c => SupabaseManager.client;

  Future<void> upsert({
    required String phone,
    required String name,
    required String address,
    String? user,
  }) async {
    final c = _c;
    if (c == null) return;
    try {
      await c.from(table).upsert({
        'phone': phone,
        'name': name,
        'address': address,
        'user': user ?? phone,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user');
    } catch (_) {
      final svc = SupabaseManager.serviceClient;
      if (svc != null) {
        try {
          await svc.from(table).upsert({
            'phone': phone,
            'name': name,
            'address': address,
            'user': user ?? phone,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user');
        } catch (_) {}
      }
    }
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
