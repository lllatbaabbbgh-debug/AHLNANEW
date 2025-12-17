import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== فحص فوري لمشكلة تسجيل الملف الشخصي ===');
  
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  final phone = '07700009999';
  final name = 'Test User Final';
  
  print('1. التحقق من وجود جدول profiles...');
  
  try {
    // التحقق من وجود الجدول
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/profiles?select=*&limit=1'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ الجدول موجود، عدد الأعمدة: ${data.length}');
      if (data.isNotEmpty) {
        print('   الأعمدة المتوفرة: ${data.first.keys.join(', ')}');
      }
    } else {
      print('❌ خطأ في الوصول للجدول: ${response.statusCode} - ${response.body}');
      return;
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
    final insertResponse = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/profiles'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode(data),
    );
    
    if (insertResponse.statusCode == 201 || insertResponse.statusCode == 200) {
      print('✅✅✅ نجحت عملية الإدخال!');
      
      // التحقق من البيانات
      final verifyResponse = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/profiles?phone=eq.$phone'),
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
      print('❌ فشلت عملية الإدخال');
      print('الخطأ التفصيلي: ${insertResponse.statusCode} - ${insertResponse.body}');
      
      if (insertResponse.body.contains('column "user" of relation "profiles" does not exist')) {
        print('!!! المشكلة الأساسية: العمود "user" غير موجود في قاعدة البيانات');
        print('!!! الحل: يجب تنفيذ كود SQL في ملف SQL_FIX_IMMEDIATE.sql');
      } else if (insertResponse.body.contains('permission denied')) {
        print('!!! المشكلة: صلاحيات غير كافية');
      } else if (insertResponse.body.contains('record "new" has no field "user"')) {
        print('!!! المشكلة: Trigger قديم يبحث عن عمود "user"');
      }
    }
  } catch (e) {
    print('❌ خطأ في الإدخال: $e');
  }
  
  print('\n=== الاختبار مكتمل ===');
}