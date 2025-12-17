import 'package:flutter/widgets.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Supabase...');
  await SupabaseManager.init();

  final client = SupabaseManager.client;
  if (client == null) {
    print('Supabase client is null');
    return;
  }

  print('Fetching one row from profiles...');
  try {
    final res = await client.from('profiles').select().limit(1);
    print('Response: $res');
    if (res.isNotEmpty) {
      print('Columns found: ${res.first.keys.toList()}');
      print('First row data: ${res.first}');
    } else {
      print('Table is empty, cannot inspect columns from data.');
      // Try to insert a dummy valid UUID to see if it accepts
    }
  } catch (e) {
    print('Error fetching: $e');
  }
}
