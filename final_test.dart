import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  print('=== اختبار نهائي للإدخال ===');
  
  // محاولة إدخال بأبسط طريقة ممكنة
  final data = {
    'phone': '07700009996',
    'name': 'Final Test User',
    'address': 'Test Address',
    'updated_at': DateTime.now().toIso8601String(),
  };
  
  try {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/profiles'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode(data),
    );
    
    print('نتيجة الإدخال: ${response.statusCode}');
    print('الرد: ${response.body}');
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅✅✅ نجح الإدخال!');
      
      // التحقق من البيانات
      final verifyResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?phone=eq.07700009996'),
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
        }
      }
    } else {
      print('❌ فشل الإدخال');
      
      // تحليل الخطأ
      if (response.body.contains('btrim(uuid)')) {
        print('\n!!! التحليل النهائي !!!');
        print('المشكلة: هناك تريجر يحاول استخدام دالة btrim على حقل UUID');
        print('الحل: يجب حذف جميع التريجرات من قاعدة البيانات');
        print('\nالكود الذي يجب تنفيذه في Supabase > SQL Editor:');
        print('---');
        print('ALTER TABLE public.profiles DISABLE TRIGGER ALL;');
        print('DROP TRIGGER IF EXISTS ALL ON public.profiles;');
        print('ALTER TABLE public.profiles ENABLE TRIGGER ALL;');
        print('---');
      }
    }
    
  } catch (e) {
    print('خطأ: $e');
  }
}