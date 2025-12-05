import 'package:flutter/material.dart';
import 'storage.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await Storage.loadTheme();
    if (savedTheme == 'light') {
      value = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    value = mode;
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await Storage.saveTheme(val);
  }
}

class ThemeProvider extends InheritedNotifier<ThemeController> {
  final ThemeController controller;
  const ThemeProvider({super.key, required this.controller, required super.child})
      : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'ThemeProvider not found');
    return provider!.controller;
  }
}
