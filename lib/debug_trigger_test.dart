import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('--- فحص الـ Trigger (Update Test) ---');
  
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';

  // رقم موجود بالفعل في القاعدة
  final phone = '07701043944';
  
  final bodyData = {
    'name': 'Updated Name Test',
    'updated_at': DateTime.now().toIso8601String(),
  };

  print('2. محاولة Update لسجل موجود...');
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
}
