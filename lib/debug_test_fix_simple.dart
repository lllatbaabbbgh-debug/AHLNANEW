import 'core/supabase_client.dart';
import 'core/repos/profile_repository.dart';

void main() async {
  print('Initializing Supabase...');
  await SupabaseManager.init();
  
  final client = SupabaseManager.client;
  if (client == null) {
    print('Supabase client is null');
    return;
  }

  print('Testing ProfileRepository upsert...');
  final repo = ProfileRepository();
  
  // اختبار مع رقم هاتف عشوائي
  final testPhone = '07700000002';
  final testName = 'اختبار جديد';
  final testAddress = 'عنوان الاختبار';
  
  print('Test: Upserting profile with phone: $testPhone');
  
  try {
    final result = await repo.upsert(
      phone: testPhone,
      name: testName,
      address: testAddress,
      user: null, // هذا يعني استخدام رقم الهاتف في user_id_text
    );
    
    print('Upsert result: $result');
    
    if (result) {
      print('Success! Fetching the profile to verify...');
      final profile = await repo.getByPhone(testPhone);
      print('Fetched profile: $profile');
    } else {
      print('Upsert failed');
    }
  } catch (e) {
    print('Error during test: $e');
  }
}
