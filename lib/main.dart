import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'core/storage.dart';
import 'core/supabase_client.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';
import 'core/cart.dart';
import 'core/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init();
  final showLogin = !(await Storage.isRegistered());
  final initialProfile = await Storage.loadProfile();
  runApp(AhlnaDaquqApp(showLoginFirst: showLogin, initialProfile: initialProfile));
}

class AhlnaDaquqApp extends StatelessWidget {
  final bool showLoginFirst;
  final Map<String, String>? initialProfile;
  const AhlnaDaquqApp({super.key, this.showLoginFirst = true, this.initialProfile});

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
    return CartProvider(
      controller: cart,
      child: ProfileProvider(
        controller: profile,
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkLuxury,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: showLoginFirst ? const LoginScreen() : const RootScaffold(),
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
    final cs = Theme.of(context).colorScheme;
    final cart = CartProvider.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'القائمة'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(cart.totalItems > 0 ? cart.totalItems.toString() : 'السلة'),
          );
        },
      ),
    );
  }
}
