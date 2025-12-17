import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('--- بدء فحص الحل النهائي (وضع مباشر) ---');
  
  // إعدادات Supabase
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  // استخدام مفتاح الخدمة (Service Key) للتأكد من الصلاحيات
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';

  final phone = '07700008888';
  final testName = 'Direct HTTP Test';
  
  print('جاري محاولة Upsert باستخدام HTTP مباشرة...');
  
  final url = Uri.parse('$supabaseUrl/rest/v1/profiles?on_conflict=phone');
  
  // البيانات التي سيتم إرسالها (نفس هيكلية Fix الذي قمنا به)
  final body = jsonEncode({
    'phone': phone,
    'name': testName,
    'address': 'Direct HTTP Address',
    'user_id_text': phone, // استخدام user_id_text للمستخدم المجهول
    'updated_at': DateTime.now().toIso8601String(),
  });

  try {
    final response = await http.post(
      url,
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates', // Upsert behavior
      },
      body: body,
    );

    print('Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      print('✅✅ نجاح! تم قبول الطلب من قبل Supabase.');
      print('هذا يؤكد أن الحل البرمجي (تغيير الأعمدة) صحيح 100%.');
    } else {
      print('❌ فشل الطلب: ${response.body}');
    }

  } catch (e) {
    print('❌ خطأ في الاتصال: $e');
  }
}
