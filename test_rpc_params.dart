import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== اختبار دالة RPC مع user_id ===');
  
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  final phone = '07709999999'; // New unique phone
  final name = 'Test User With ID';
  final address = 'Test Address';
  final userId = '00000000-0000-0000-0000-000000000001'; // Fake UUID
  
  print('1. محاولة استدعاء RPC مع p_user_id...');
  
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
        'p_user_id': userId, // Try passing this
      }),
    );
    
    if (response.statusCode == 200) {
      print('✅ نجح مع p_user_id!');
      print(response.body);
    } else {
      print('❌ فشل مع p_user_id: ${response.body}');
      
      // Try with p_user instead
      print('2. محاولة استدعاء RPC مع p_user...');
      final response2 = await http.post(
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
          'p_user': userId,
        }),
      );
      
      if (response2.statusCode == 200) {
         print('✅ نجح مع p_user!');
         print(response2.body);
      } else {
         print('❌ فشل مع p_user: ${response2.body}');
      }
    }
  } catch (e) {
    print('❌ خطأ: $e');
  }
}