import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage.dart';

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
    var url = SupabaseConfig.supabaseUrl;
    var key = SupabaseConfig.supabaseAnonKey;
    if (url.isEmpty || key.isEmpty) {
      final conf = await Storage.loadSupabaseConfig();
      url = conf['url'] ?? '';
      key = conf['anon'] ?? '';
    }
    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: key);
      // Persist for future debug runs without dart-define
      await Storage.saveSupabaseConfig(url: url, anonKey: key);
    }
    _initialized = true;
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static SupabaseClient? get serviceClient {
    final url = SupabaseConfig.supabaseUrl;
    final svc = SupabaseConfig.supabaseServiceKey;
    if (url.isEmpty || svc.isEmpty) return null;
    return SupabaseClient(url, svc);
  }
}
