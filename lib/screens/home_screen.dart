import 'package:flutter/material.dart';
import '../core/cart.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';
import 'details_screen.dart';
import '../core/repos/food_repository.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final repo = FoodRepository();
  final LiquidController _liquid = LiquidController();
  bool _prefetched = false;

  static const List<String> _categories = ['Lahm Bi Ajeen', 'Pizza', 'Drinks'];
  static const Map<String, String> _categoryAr = {
    'Lahm Bi Ajeen': 'لحم بعجين',
    'Pizza': 'بيتزا',
    'Drinks': 'مشروبات',
  };

  late final List<Widget> _pages;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _prefetchAll();
  }

  Future<void> _prefetchAll() async {
    final builtPages = <Widget>[];
    for (final c in _categories) {
      final items = await repo.fetchByCategory(c);
      builtPages.add(_CategoryPage(
        key: ValueKey<String>(c),
        category: c,
        initialItems: items,
        stream: repo.liveByCategory(c),
      ));
    }
    _pages = builtPages;
    if (mounted) setState(() => _prefetched = true);
  }

  Stream<List<FoodItem>> _streamByCategory(String c) => repo.liveByCategory(c);

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    if (!_prefetched) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('أهلنا داقوق'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((c) => Tab(text: _categoryAr[c])).toList(),
          labelPadding: const EdgeInsets.symmetric(vertical: 10),
          indicatorColor: Theme.of(context).colorScheme.primary,
          onTap: (index) {
            _liquid.animateToPage(page: index);
          },
        ),
      ),
      body: LiquidSwipe(
        pages: _pages,
        waveType: WaveType.liquidReveal,
        enableLoop: true,
        enableSideReveal: false,
        liquidController: _liquid,
        initialPage: _tabController.index,
        fullTransitionValue: 300,
        ignoreUserGestureWhileAnimating: true,
        onPageChangeCallback: (i) {
          if (_tabController.index != i) _tabController.animateTo(i);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _CategoryPage extends StatefulWidget {
  final String category;
  final List<FoodItem> initialItems;
  final Stream<List<FoodItem>> stream;
  const _CategoryPage({super.key, required this.category, required this.initialItems, required this.stream});

  @override
  State<_CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<_CategoryPage> with AutomaticKeepAliveClientMixin {
  late List<FoodItem> _items = widget.initialItems;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.stream.listen((data) {
      setState(() => _items = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      constraints: const BoxConstraints.expand(),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final cart = CartProvider.of(context);
                  final FoodItem item = _items[index];
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
      ),
    );
  }
}
