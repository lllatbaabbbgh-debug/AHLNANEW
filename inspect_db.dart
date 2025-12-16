import 'lib/core/supabase_client.dart';

void main() async {
  print('جاري فحص هيكلية جدول food_items...');
  await SupabaseManager.init();
  final client = SupabaseManager.client;
  
  if (client == null) {
    print('فشل الاتصال');
    return;
  }

  try {
    final res = await client.from('food_items').select().limit(1);
    if (res.isNotEmpty) {
      final row = res.first;
      print('الأعمدة المتوفرة:');
      for (var k in row.keys) {
        print('- $k');
      }
      
      if (row.containsKey('sort_order')) {
        print('✅ عمود sort_order موجود!');
      } else {
        print('❌ عمود sort_order غير موجود.');
      }
    } else {
      print('الجدول فارغ، لا يمكن تحديد الأعمدة.');
    }
  } catch (e) {
    print('خطأ: $e');
  }
}
