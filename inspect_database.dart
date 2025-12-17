import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  print('=== فحص شامل لقاعدة البيانات ===');
  
  try {
    // التحقق من التريجرات
    print('1. التحقق من التريجرات...');
    final triggersResponse = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': """
          SELECT trigger_name, event_object_table, action_statement 
          FROM information_schema.triggers 
          WHERE event_object_table = 'profiles' AND trigger_schema = 'public'
        """
      }),
    );
    
    print('النتيجة: ${triggersResponse.statusCode} - ${triggersResponse.body}');
    
    // التحقق من البيانات الموجودة
    print('2. التحقق من البيانات الموجودة...');
    final dataResponse = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/profiles?select=*&limit=5'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
      },
    );
    
    print('البيانات: ${dataResponse.statusCode} - ${dataResponse.body}');
    
    // محاولة إدخال بسيط بدون user_id
    print('3. محاولة إدخال بسيط...');
    final simpleData = {
      'phone': '07700009998',
      'name': 'Simple Test',
      'address': 'Test Address',
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    final simpleResponse = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/profiles'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode(simpleData),
    );
    
    print('النتيجة البسيطة: ${simpleResponse.statusCode} - ${simpleResponse.body}');
    
  } catch (e) {
    print('خطأ: $e');
  }
}