import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== اختبار تحديث user_id ===');
  
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  final phone = '07701234567'; // The phone used in test_rpc_function.dart
  final userId = '00000000-0000-0000-0000-000000000001'; // Fake UUID
  
  print('1. محاولة تحديث user_id للمستخدم $phone...');
  
  try {
    final response = await http.patch(
      Uri.parse('$supabaseUrl/rest/v1/profiles?phone=eq.$phone'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      print('✅ تم تحديث user_id بنجاح!');
    } else {
      print('❌ فشل التحديث: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ خطأ: $e');
  }
}