import 'package:flutter/material.dart';
import '../core/cart.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';
import '../widgets/staggered_entrance.dart';
import 'details_screen.dart';
import '../core/repos/food_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = FoodRepository();
  final Map<String, List<FoodItem>> _cache = {};

  static const List<String> _categories = ['Lahm Bi Ajeen', 'Pizza', 'Drinks'];
  static const Map<String, String> _categoryAr = {
    'Lahm Bi Ajeen': 'لحم بعجين',
    'Pizza': 'بيتزا',
    'Drinks': 'مشروبات',
  };

  Stream<List<FoodItem>> _streamByCategory(String c) => repo.liveByCategory(c);

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أهلنا داقوق'),
          bottom: TabBar(
            tabs: _categories.map((c) => Tab(text: _categoryAr[c])).toList(),
            labelPadding: const EdgeInsets.symmetric(vertical: 10),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          actions: const [],
        ),
        body: TabBarView(
          children: _categories.map((cat) {
            return StreamBuilder<List<FoodItem>>(
              stream: _streamByCategory(cat),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('❌ Error loading items for $cat: ${snapshot.error}');
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  _cache[cat] = snapshot.data ?? const <FoodItem>[];
                }
                final items = snapshot.hasData
                    ? (snapshot.data ?? const <FoodItem>[])
                    : (_cache[cat] ?? const <FoodItem>[]);
                if (!snapshot.hasData && items.isEmpty) {
                  print('⏳ Initial load for $cat...');
                  return const Center(child: CircularProgressIndicator());
                }
                print('✅ Loaded ${items.length} items for $cat');
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final FoodItem item = items[index];
                      final dimmed = !item.isAvailable;
                      return Opacity(
                        opacity: dimmed ? 0.45 : 1.0,
                        child: IgnorePointer(
                          ignoring: dimmed,
                          child: FoodCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(item: item),
                                ),
                              );
                            },
                            onAdd: () {
                              cart.add(item);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
