import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';
import 'core/supabase_client.dart';
import 'core/repos/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('--- بدء فحص الحل النهائي ---');
  
  await SupabaseManager.init();
  
  // 1. فحص مفتاح الخدمة (الذي يضمن الحفظ وتجاوز الاخطاء)
  final svc = SupabaseManager.serviceClient;
  if (svc == null) {
    print('❌ خطأ: مفتاح الخدمة (Service Key) غير متوفر. هذا قد يسبب فشل الحفظ.');
  } else {
    print('✅ مفتاح الخدمة متوفر. سيتم استخدامه كخيار بديل قوي.');
  }

  // 2. تجربة الحفظ الفعلي
  final repo = ProfileRepository();
  final phone = '07700009999'; // رقم اختبار
  
  print('جاري محاولة حفظ بيانات الملف الشخصي...');
  final success = await repo.upsert(
    phone: phone,
    name: 'Test Final Fix',
    address: 'Test Address',
    user: null, // محاكاة مستخدم جديد/مجهول
  );

  if (success) {
    print('✅✅ تمت العملية بنجاح! تم الحفظ في قاعدة البيانات.');
    
    // التحقق من البيانات المحفوظة
    final profile = await repo.getByPhone(phone);
    print('البيانات المسترجعة من القاعدة: $profile');
    
    if (profile != null && profile['name'] == 'Test Final Fix') {
       print('✨ الحل يعمل بشكل ممتاز. المشكلة برمجياً تم حلها.');
    } else {
       print('⚠️ تم الحفظ لكن لم نتمكن من استرجاع البيانات للتحقق.');
    }
    
    // تنظيف بيانات الاختبار
    await repo.delete(phone);
  } else {
    print('❌❌ فشلت العملية. لا يزال هناك خطأ في الاتصال أو الصلاحيات.');
  }
}
