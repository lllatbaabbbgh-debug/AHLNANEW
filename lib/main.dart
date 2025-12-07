import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage.dart';
import 'core/supabase_client.dart';
import 'core/theme_controller.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'core/cart.dart';
import 'core/profile.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Hive.initFlutter();
  await Hive.openBox('food_cache');
  await Hive.openBox('offers_cache');
  
  await SupabaseManager.init();
  final showLogin = !(await Storage.isRegistered());
  final initialProfile = await Storage.loadProfile();
  final themeController = ThemeController();

  // Add 0.5s delay before removing splash screen
  await Future.delayed(const Duration(milliseconds: 500));
  FlutterNativeSplash.remove();

  runApp(
    AhlnaDaquqApp(
      showLoginFirst: showLogin, 
      initialProfile: initialProfile,
      themeController: themeController,
    ),
  );
}

class AhlnaDaquqApp extends StatelessWidget {
  final bool showLoginFirst;
  final Map<String, String>? initialProfile;
  final ThemeController themeController;

  const AhlnaDaquqApp({
    super.key,
    this.showLoginFirst = true,
    this.initialProfile,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    final cart = CartController();
    final profile = ProfileController();

    if (initialProfile != null) {
      final name = initialProfile!["name"] ?? '';
      final phone = initialProfile!["phone"] ?? '';
      final address = initialProfile!["address"] ?? '';
      if (name.isNotEmpty || phone.isNotEmpty || address.isNotEmpty) {
        profile.set(name: name, phone: phone, address: address);
      }
    }
    
    // تحميل صورة البروفايل عند بدء التطبيق
    Storage.loadProfileImage().then((path) {
      if (path != null && path.isNotEmpty) {
        profile.set(imagePath: path);
      }
    });

    return CartProvider(
      controller: cart,
      child: ProfileProvider(
        controller: profile,
        child: ThemeProvider(
          controller: themeController,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                darkTheme: ThemeData(
                  useMaterial3: true,
                  brightness: Brightness.dark,
                  primaryColor: const Color(0xFF23AA49),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF23AA49),
                    secondary: Color(0xFF23AA49),
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    onPrimary: Colors.white,
                    outline: Color(0xFF424242),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFF1E1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    surfaceTintColor: Colors.transparent,
                    iconTheme: IconThemeData(color: Colors.white),
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    backgroundColor: Color(0xFF1E1E1E),
                    selectedItemColor: Color(0xFF23AA49),
                    unselectedItemColor: Colors.grey,
                    elevation: 15,
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIconColor: const Color(0xFF23AA49),
                    suffixIconColor: Colors.grey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF23AA49),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF23AA49),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  textTheme: const TextTheme(
                    headlineSmall: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    titleLarge: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    bodyLarge: TextStyle(color: Colors.white),
                    bodyMedium: TextStyle(color: Colors.white70),
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: const Color(0xFF1E1E1E),
                    surfaceTintColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ============================================================
                // 🎨 ثيم HyperMart (أخضر عصري + خلفية نظيفة)
                // ============================================================
                theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,

            // 1. اللون الرئيسي (HyperMart Green)
            // اذا كان اللون في الرابط مختلف، فقط غير هذا الكود (0xFF23AA49) للون الذي تريده
            primaryColor: const Color(0xFF23AA49),

            // خلفية رمادية فاتحة جداً (Cool Gray)
            scaffoldBackgroundColor: const Color(0xFFF6F7F9),

            // 2. مخطط الألوان
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF23AA49), // الأخضر
              secondary: Color(0xFF23AA49),
              surface: Colors.white, // لون البطاقات أبيض ناصع
              onSurface: Color(0xFF1B1B1B), // لون النصوص أسود غامق
              onPrimary: Colors.white, // لون النص داخل الزر الأخضر
              outline: Color(0xFFE1E1E1), // لون الحدود فاتح
            ),

            // 3. شريط العنوان (AppBar)
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, // خلفية بيضاء
              foregroundColor: Color(0xFF1B1B1B), // أيقونات ونص أسود
              elevation: 0,
              centerTitle: true,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: Color(0xFF1B1B1B)),
              titleTextStyle: TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo', // اذا كنت تستخدم خط معين
              ),
            ),

            // 4. الشريط السفلي (Bottom Navigation)
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color.fromARGB(255, 67, 179, 33), // أخضر عند الاختيار
              unselectedItemColor: Color(0xFF9E9E9E), // رمادي عند عدم الاختيار
              elevation: 15,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
            ),

            // 5. حقول الإدخال (Inputs) - مثل تصميم فيجما
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF3F3F3), // رمادي فاتح جداً
              hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIconColor: const Color(0xFF23AA49),
              suffixIconColor: const Color(0xFFBDBDBD),

              // الحدود
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none, // بدون حدود افتراضية
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF23AA49),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
            ),

            // 6. الأزرار (Buttons)
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF23AA49),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // 7. النصوص (Typography)
            textTheme: const TextTheme(
              headlineSmall: TextStyle(
                color: Color(0xFF1B1B1B),
                fontWeight: FontWeight.bold,
              ),
              titleLarge: TextStyle(
                color: Color(0xFF1B1B1B),
                fontWeight: FontWeight.bold,
              ),
              bodyLarge: TextStyle(color: Color(0xFF1B1B1B)),
              bodyMedium: TextStyle(color: Color(0xFF424242)),
            ),

            // 8. القوائم
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ============================================================
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: showLoginFirst ? const LoginScreen() : const RootScaffold(),
        );
            },
          ),
        ),
      ),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}


class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeScreen(key: ValueKey('tab_menu')),
      const ProfileScreen(key: ValueKey('tab_profile')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.storefront_rounded,
              ), // تغيير الأيقونة لتناسب الماركت
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
