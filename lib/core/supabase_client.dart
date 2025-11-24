import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const supabaseServiceKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
  );
}

class SupabaseManager {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    final url = SupabaseConfig.supabaseUrl;
    final key = SupabaseConfig.supabaseAnonKey;
    if (url.isEmpty || key.isEmpty) {
      _initialized = true;
      return;
    }
    await Supabase.initialize(url: url, anonKey: key);
    _initialized = true;
  }

  static SupabaseClient? get client =>
      (SupabaseConfig.supabaseUrl.isEmpty ||
          SupabaseConfig.supabaseAnonKey.isEmpty)
      ? null
      : Supabase.instance.client;

  static SupabaseClient? get serviceClient =>
      (SupabaseConfig.supabaseUrl.isEmpty ||
          SupabaseConfig.supabaseServiceKey.isEmpty)
      ? null
      : SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.supabaseServiceKey,
        );
}
