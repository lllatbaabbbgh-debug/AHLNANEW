import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kRegistered = 'registered';
  static const _kName = 'name';
  static const _kPhone = 'phone';
  static const _kAddress = 'address';

  static Future<bool> isRegistered() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRegistered) ?? false;
  }

  static Future<void> saveProfile({required String name, required String phone, required String address}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kPhone, phone);
    await p.setString(_kAddress, address);
    await p.setBool(_kRegistered, true);
  }

  static Future<Map<String, String>> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name': p.getString(_kName) ?? '',
      'phone': p.getString(_kPhone) ?? '',
      'address': p.getString(_kAddress) ?? '',
    };
  }
}

