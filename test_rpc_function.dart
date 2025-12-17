import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('=== اختبار دالة RPC لإنشاء الملف الشخصي ===');
  
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  final phone = '07701234567';
  final name = 'Ali';
  final address = 'Baghdad';
  
  print('1. اختبار دالة rpc_create_profile...');
  
  try {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/rpc_create_profile'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'p_name': name,
        'p_phone': phone,
        'p_address': address,
      }),
    );
    
    if (response.statusCode == 200) {
      print('✅✅✅ نجحت دالة RPC!');
      print('النتيجة: ${response.body}');
      
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
          print('   العنوان: ${result[0]['address']}');
        }
      }
    } else {
      print('❌ فشلت دالة RPC');
      print('الخطأ: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ خطأ في اختبار RPC: $e');
  }
  
  print('\n=== الاختبار مكتمل ===');
}