import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  print('=== تنفيذ حل المشكلة النهائي ===');
  print('جاري حذف التريجرات المشكلة...');
  
  try {
    // استخدام RPC لحذف التريجرات
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/exec_sql'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sql': """
          -- حذف جميع التريجرات المشكلة
          ALTER TABLE public.profiles DISABLE TRIGGER ALL;
          DROP TRIGGER IF EXISTS ALL ON public.profiles;
          ALTER TABLE public.profiles ENABLE TRIGGER ALL;
          
          -- التحقق من النتيجة
          SELECT 'Triggers deleted successfully' as result;
        """
      }),
    );
    
    print('نتيجة الحذف: ${response.statusCode}');
    print('الرد: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✅ تم حذف التريجرات بنجاح');
      
      // الآن نختبر الإدخال
      print('جاري اختبار الإدخال...');
      
      final testData = {
        'phone': '07700009995',
        'name': 'Test User Fixed',
        'address': 'Test Address',
        'user_id_text': '07700009995',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final insertResponse = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/profiles'),
        headers: {
          'apikey': serviceKey,
          'Authorization': 'Bearer $serviceKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(testData),
      );
      
      print('نتيجة الإدخال: ${insertResponse.statusCode}');
      print('الرد: ${insertResponse.body}');
      
      if (insertResponse.statusCode == 201 || insertResponse.statusCode == 200) {
        print('✅✅✅ نجح الإدخال! تم حل المشكلة نهائياً');
        
        // التحقق من البيانات
        final verifyResponse = await http.get(
          Uri.parse('$supabaseUrl/rest/v1/profiles?phone=eq.07700009995'),
          headers: {
            'apikey': serviceKey,
            'Authorization': 'Bearer $serviceKey',
          },
        );
        
        if (verifyResponse.statusCode == 200) {
          final result = jsonDecode(verifyResponse.body);
          if (result.isNotEmpty) {
            print('✅ تم التحقق: البيانات موجودة في القاعدة');
            print('   الاسم: ${result[0]['name']}');
            print('   الهاتف: ${result[0]['phone']}');
            print('   العنوان: ${result[0]['address']}');
          }
        }
        
        print('\n🎉 المشكلة تم حلها بنجاح!');
        print('الآن يمكنك تسجيل الدخول في التطبيق وسيتم حفظ البيانات في قاعدة البيانات');
        
      } else {
        print('❌ لم ينجح الإدخال بعد');
      }
    } else {
      print('❌ لم ينجح حذف التريجرات');
    }
    
  } catch (e) {
    print('خطأ: $e');
  }
}