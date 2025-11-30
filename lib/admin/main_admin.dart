import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_menu_screen.dart';
import 'screens/admin_records_screen.dart';
import 'screens/admin_offers_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init();
  runApp(const AhlnaAdminApp());
}

class AhlnaAdminApp extends StatelessWidget {
  const AhlnaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkLuxury,
      home: const AdminRoot(),
      locale: const Locale('ar'),
    );
  }
}

class AdminRoot extends StatefulWidget {
  const AdminRoot({super.key});

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const AdminHomeScreen(),
      const AdminMenuScreen(),
      const AdminRecordsScreen(),
      const AdminOffersScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة إدارة أهلنا داقوق')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('أهلنا داقوق', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('الطلبات'),
              selected: _index == 0,
              onTap: () {
                setState(() => _index = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('إدارة المنيو'),
              selected: _index == 1,
              onTap: () {
                setState(() => _index = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('سجل الطلبات'),
              selected: _index == 2,
              onTap: () {
                setState(() => _index = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('العروضات'),
              selected: _index == 3,
              onTap: () {
                setState(() => _index = 3);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: screens[_index],
    );
  }
}
