import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('=== فحص فوري لمشكلة تسجيل الملف الشخصي ===');

  // استخدام مفتاح الخدمة للحصول على أقصى صلاحيات
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';

  final supabase = SupabaseClient(supabaseUrl, serviceKey);

  final phone = '07700009999';
  final name = 'Test User Final';
  
  print('1. التحقق من وجود جدول profiles...');
  
  try {
    final columns = await supabase.from('profiles').select('*').limit(1);
    print('✅ الجدول موجود، عدد الأعمدة: ${columns.length}');
    if (columns.isNotEmpty) {
      print('   الأعمدة المتوفرة: ${columns.first.keys.join(', ')}');
    }
  } catch (e) {
    print('❌ خطأ في الوصول للجدول: $e');
    return;
  }

  print('2. محاولة إدخال بيانات اختبارية...');
  
  final data = {
    'phone': phone,
    'name': name,
    'address': 'Test Address',
    'user_id_text': phone,
    'updated_at': DateTime.now().toIso8601String(),
  };

  try {
    await supabase.from('profiles').upsert(data, onConflict: 'phone');
    print('✅✅✅ نجحت عملية الإدخال!');
    
    // التحقق من أن البيانات ظهرت فعلاً
    final result = await supabase.from('profiles').select().eq('phone', phone).single();
    print('✅ تم التحقق: البيانات موجودة في القاعدة');
    print('   الاسم: ${result['name']}');
    print('   الهاتف: ${result['phone']}');
    
  } catch (e) {
    print('❌ فشلت عملية الإدخال');
    print('الخطأ التفصيلي: $e');
    
    if (e.toString().contains('column "user" of relation "profiles" does not exist')) {
      print('!!! المشكلة الأساسية: العمود "user" غير موجود في قاعدة البيانات');
      print('!!! الحل: يجب تنفيذ كود SQL في ملف SQL_FIX_IMMEDIATE.sql');
    } else if (e.toString().contains('permission denied')) {
      print('!!! المشكلة: صلاحيات غير كافية');
    } else if (e.toString().contains('record "new" has no field "user"')) {
      print('!!! المشكلة: Trigger قديم يبحث عن عمود "user"');
    }
  }
  
  print('3. التحقق من الصلاحيات...');
  try {
    final policies = await supabase.rpc('get_policies', params: {'table_name': 'profiles'});
    print('صلاحيات الجدول: $policies');
  } catch (e) {
    print('لا يمكن التحقق من الصلاحيات: $e');
  }
}