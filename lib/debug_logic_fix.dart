import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('--- تجربة منطق بديل (Check then Insert/Update) ---');
  
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';

  final phone = '07700007777';
  
  // 1. Check if exists
  print('1. فحص وجود المستخدم...');
  final checkUrl = Uri.parse('$supabaseUrl/rest/v1/profiles?phone=eq.$phone&select=*');
  final checkRes = await http.get(checkUrl, headers: {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
  });
  
  bool exists = false;
  if (checkRes.statusCode == 200) {
    final List data = jsonDecode(checkRes.body);
    if (data.isNotEmpty) exists = true;
  }
  
  print('User exists: $exists');
  
  final bodyData = {
    'phone': phone,
    'name': 'Logic Test',
    'address': 'Logic Address',
    'user_id_text': phone,
    'updated_at': DateTime.now().toIso8601String(),
  };

  if (exists) {
    print('2. محاولة Update...');
    final updateUrl = Uri.parse('$supabaseUrl/rest/v1/profiles?phone=eq.$phone');
    final res = await http.patch(
      updateUrl,
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyData),
    );
    print('Update Status: ${res.statusCode}');
    print('Update Body: ${res.body}');
  } else {
    print('2. محاولة Insert...');
    final insertUrl = Uri.parse('$supabaseUrl/rest/v1/profiles');
    final res = await http.post(
      insertUrl,
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyData),
    );
    print('Insert Status: ${res.statusCode}');
    print('Insert Body: ${res.body}');
  }
}
