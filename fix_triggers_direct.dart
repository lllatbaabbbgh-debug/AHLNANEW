import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
  
  print('=== تنفيذ SQL لحل مشكلة التريجر ===');
  
  // SQL لحذف جميع التريجرات المشكلة
  final sqlCommands = """
    -- إيقاف جميع التريجرات مؤقتاً
    ALTER TABLE public.profiles DISABLE TRIGGER ALL;
    
    -- حذف جميع التريجرات المشكلة
    DROP TRIGGER IF EXISTS update_profiles_trigger ON public.profiles;
    DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
    DROP TRIGGER IF EXISTS handle_profiles_update ON public.profiles;
    DROP TRIGGER IF EXISTS trigger_profiles_update ON public.profiles;
    DROP TRIGGER IF EXISTS profiles_timestamp_update ON public.profiles;
    DROP TRIGGER IF EXISTS simple_profiles_insert_trigger ON public.profiles;
    
    -- حذف جميع الدوال المشكلة
    DROP FUNCTION IF EXISTS public.update_profiles();
    DROP FUNCTION IF EXISTS public.handle_profiles_update();
    DROP FUNCTION IF EXISTS public.profiles_updated_at();
    DROP FUNCTION IF EXISTS public.update_profiles_timestamp();
    DROP FUNCTION IF EXISTS public.simple_profiles_insert();
    
    -- إعادة تفعيل التريجرات مع تركها فارغة
    ALTER TABLE public.profiles ENABLE TRIGGER ALL;
    
    -- التحقق من النتيجة
    SELECT trigger_name, event_object_table, action_statement 
    FROM information_schema.triggers 
    WHERE event_object_table = 'profiles' AND trigger_schema = 'public';
  """;
  
  try {
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/query'),
      headers: {
        'apikey': serviceKey,
        'Authorization': 'Bearer $serviceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': sqlCommands
      }),
    );
    
    print('نتيجة تنفيذ SQL: ${response.statusCode}');
    print('الرد: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✅ تم حذف التريجرات المشكلة بنجاح');
      
      // الآن نحاول الإدخال مرة أخرى
      print('2. محاولة الإدخال بعد حذف التريجرات...');
      
      final data = {
        'phone': '07700009997',
        'name': 'Test After Fix',
        'address': 'Test Address',
        'user_id_text': '07700009997',
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
        body: jsonEncode(data),
      );
      
      print('نتيجة الإدخال: ${insertResponse.statusCode} - ${insertResponse.body}');
      
      if (insertResponse.statusCode == 201 || insertResponse.statusCode == 200) {
        print('✅✅✅ نجح الإدخال! تم حل المشكلة نهائياً');
      }
    }
    
  } catch (e) {
    print('خطأ: $e');
  }
}