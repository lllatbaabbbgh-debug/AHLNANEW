import 'package:flutter/material.dart';
import '../core/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeProvider.of(context);
    final mode = themeController.value;
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'المظهر',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: GestureDetector(
              onTap: () {
                final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                themeController.setTheme(newMode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : const Color(0xFFFFE0B2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.orange.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Sun Icon (Left)
                    Align(
                      alignment: const Alignment(-0.8, 0),
                      child: Icon(
                        Icons.wb_sunny_rounded,
                        color: isDark ? Colors.grey[700] : Colors.orange,
                        size: 28,
                      ),
                    ),
                    
                    // Moon Icon (Right)
                    Align(
                      alignment: const Alignment(0.8, 0),
                      child: Icon(
                        Icons.nightlight_round,
                        color: isDark ? Colors.blue[300] : Colors.grey[400],
                        size: 28,
                      ),
                    ),

                    // The Toggle Button
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutBack,
                      alignment: isDark ? const Alignment(1.0, 0) : const Alignment(-1.0, 0),
                      child: Container(
                        width: 100,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFFDB813),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.blue : Colors.orange).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isDark ? 'Dark' : 'Light',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
