import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/cart.dart';
import '../core/profile.dart';
import '../models/food_item.dart';
import 'details_screen.dart';
import 'settings_screen.dart';
import 'cart_screen.dart';
import '../core/repos/food_repository.dart';
import '../core/repos/offers_repository.dart';
import '../core/repos/category_repository.dart';
import '../models/category_model.dart';
import 'category_content.dart';
import '../core/ui_utils.dart';
import '../core/animations/fly_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final repo = FoodRepository();
  final catRepo = CategoryRepository();
  // bool _prefetched = false; // Removed unused field
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _search = ValueNotifier<String>('');

  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _parentCategories = [];
  bool _loadingCategories = true;
  final Map<int, CategoryModel?> _selectedChildForParent = {};

  TabController? _tabController;

  final ValueNotifier<String?> _offerLink = ValueNotifier<String?>(null);
  final _offersRepo = OffersRepository();
  StreamSubscription<String?>? _offerSub;
  CategoryModel? _selectedParent;
  StreamSubscription<List<CategoryModel>>? _catStream;
  final GlobalKey _cartKey = GlobalKey();
  final Box _offersBox = Hive.box('offers_cache');

  String _categoryKey(CategoryModel m) {
    final en = m.nameEn.trim();
    if (en.isNotEmpty) return en;
    return m.nameAr.trim();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _loadCategories();
    _subscribeCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await catRepo.getAllCategories();
      if (mounted) {
        setState(() {
          if (cats.isEmpty) {
             // Fallback
             _allCategories = [
               const CategoryModel(id: 1, nameEn: 'Lahm Bi Ajeen', nameAr: 'لحم بعجين'),
               const CategoryModel(id: 2, nameEn: 'Pizza', nameAr: 'بيتزا'),
               const CategoryModel(id: 3, nameEn: 'Drinks', nameAr: 'مشروبات'),
             ];
          } else {
             _allCategories = cats;
          }
          _parentCategories = _allCategories.where((c) => c.parentId == null).toList();
          _tabController = TabController(length: _parentCategories.length, vsync: this);
          _loadingCategories = false;
          if (_selectedParent == null && _parentCategories.isNotEmpty) {
            _selectedParent = _parentCategories.first;
            final children = _allCategories.where((c) => c.parentId == _selectedParent!.id).toList();
            if (children.isNotEmpty && _selectedChildForParent[_selectedParent!.id] == null) {
              _selectedChildForParent[_selectedParent!.id] = children.first;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      // Fallback
      if (mounted) {
        setState(() {
          _allCategories = [
             const CategoryModel(id: 1, nameEn: 'Lahm Bi Ajeen', nameAr: 'لحم بعجين'),
             const CategoryModel(id: 2, nameEn: 'Pizza', nameAr: 'بيتزا'),
             const CategoryModel(id: 3, nameEn: 'Drinks', nameAr: 'مشروبات'),
          ];
          _parentCategories = _allCategories;
          _tabController = TabController(length: _parentCategories.length, vsync: this);
          _loadingCategories = false;
          if (_selectedParent == null && _parentCategories.isNotEmpty) {
            _selectedParent = _parentCategories.first;
            final children = _allCategories.where((c) => c.parentId == _selectedParent!.id).toList();
            if (children.isNotEmpty && _selectedChildForParent[_selectedParent!.id] == null) {
              _selectedChildForParent[_selectedParent!.id] = children.first;
            }
          }
        });
      }
    }
  }

  void _subscribeCategories() {
    _catStream?.cancel();
    _catStream = catRepo.streamCategories().listen((cats) {
      if (!mounted) return;
      setState(() {
        _allCategories = cats;
        _parentCategories = _allCategories.where((c) => c.parentId == null).toList();
        if (_selectedParent == null && _parentCategories.isNotEmpty) {
          _selectedParent = _parentCategories.first;
        }
        final p = _selectedParent;
        if (p != null) {
          final children = _allCategories.where((c) => c.parentId == p.id).toList();
          if (children.isNotEmpty && _selectedChildForParent[p.id] == null) {
            _selectedChildForParent[p.id] = children.first;
          }
        }
      });
    });
  }

  Future<void> _initializeApp() async {
    try {
      await _loadOfferLink();
    } catch (e) {
      print('خطأ في تحميل التطبيق: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadOfferLink() async {
    // 1. Load from local cache immediately
    final cachedLink = _offersBox.get('offer_link') as String?;
    if (cachedLink != null) {
      _offerLink.value = cachedLink;
    }

    try {
      final link = await _offersRepo.getLink().timeout(
        const Duration(seconds: 5),
      );
      // 2. Update cache and UI
      if (link != null) {
        _offerLink.value = link;
        await _offersBox.put('offer_link', link);
      }
      
      _offerSub = _offersRepo.liveLink().listen((l) {
        if (l != null) {
          _offerLink.value = l;
          _offersBox.put('offer_link', l);
        }
      });
    } catch (e) {
      // في حال الخطأ نُبقي القيمة الحالية كما هي
    }
  }

  // Future<void> _prefetchAll() async { // Removed unused method
  //   try {
  //     final futures = _categories.map((c) async {
  //       try {
  //         final items = await repo
  //             .fetchByCategory(c)
  //             .timeout(const Duration(seconds: 10));
  //         print(
  //           '✅ تم تحميل قسم ${_categoryAr[c]} بنجاح مع ${items.length} عنصر',
  //         );
  //         return _CategoryPage(
  //           key: ValueKey<String>(c),
  //           category: c,
  //           initialItems: items,
  //           stream: repo.liveByCategory(c),
  //           search: _search,
  //           offerLink: _offerLink,
  //           cartKey: _cartKey,
  //         );
  //       } catch (e) {
  //         print('⚠️ خطأ في تحميل قسم $c: $e');
  //         return _CategoryPage(
  //           key: ValueKey<String>(c),
  //           category: c,
  //           initialItems: const [],
  //           stream: const Stream<List<FoodItem>>.empty(),
  //           search: _search,
  //           offerLink: _offerLink,
  //           cartKey: _cartKey,
  //         );
  //       }
  //     }).toList();
  //
  //     final builtPages = await Future.wait(futures);
  //     // _pages = builtPages; // Removed unused variable
  //     if (mounted) {
  //       // setState(() => _prefetched = true); // Removed unused variable
  //       print('✅ تم تحميل جميع الأقسام بالتوازي بنجاح');
  //     }
  //   } catch (e) {
  //     print('❌ خطأ عام في تحميل الأقسام: $e');
  //     if (mounted) {
  //       // setState(() => _prefetched = true); // Removed unused variable
  //     }
  //   }
  // }

  // Stream<List<FoodItem>> _streamByCategory(String c) => repo.liveByCategory(c); // Removed unused method

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark; // Removed unused variable

    if (_loadingCategories || _tabController == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
      );
    }

    final cart = CartProvider.of(context);
    final profile = ProfileProvider.of(context);

    return Scaffold(
      
      backgroundColor: theme.scaffoldBackgroundColor,
      
      // --- AppBar ---
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _search.value = val,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: 'ابحث عن وجبتك المفضلة...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: theme.primaryColor),
              suffixIcon: ValueListenableBuilder<String>(
                valueListenable: _search,
                builder: (context, val, _) {
                  if (val.isEmpty) return const SizedBox();
                  return IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _search.value = '';
                    },
                  );
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor ?? Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),

        // --- أيقونة السلة ---
        leading: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedBuilder(
            animation: cart,
            builder: (context, child) {
              final hasItems = cart.items.isNotEmpty;
              final itemCount = cart.totalItems;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    key: _cartKey,
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                      color: hasItems ? Colors.redAccent : theme.iconTheme.color,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (hasItems)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // --- القائمة الجانبية ---
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: theme.iconTheme.color,
                size: 30,
              ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],

        // --- التبويبات ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildTopNavBar(context),
        ),
      ),

      endDrawer: _buildLuxuryDrawer(context),

      body: _buildContentView(),
    );
  }

  Widget _buildTopNavBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _parentCategories.map((p) {
            final isActive = _selectedParent?.id == p.id;
            final children = _allCategories.where((c) => c.parentId == p.id).toList();
            if (children.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: PopupMenuButton<CategoryModel>(
                  tooltip: p.nameAr,
                  onSelected: (c) {
                    setState(() {
                      _selectedParent = p;
                      _selectedChildForParent[p.id] = c;
                    });
                  },
                  itemBuilder: (context) => children
                      .map((c) => PopupMenuItem<CategoryModel>(
                            value: c,
                            child: Text(c.nameAr),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? theme.primaryColor.withOpacity(0.12) : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? theme.primaryColor : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Text(
                          p.nameAr,
                          style: TextStyle(
                            color: isActive ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.expand_more,
                          size: 18,
                          color: isActive ? theme.primaryColor : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedParent = p;
                    _selectedChildForParent.remove(p.id);
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? theme.primaryColor.withOpacity(0.12) : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? theme.primaryColor : Colors.grey.shade300),
                  ),
                  child: Text(
                    p.nameAr,
                    style: TextStyle(
                      color: isActive ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    final p = _selectedParent ?? (_parentCategories.isNotEmpty ? _parentCategories.first : null);
    if (p == null) {
      return const SizedBox();
    }
    final children = _allCategories.where((c) => c.parentId == p.id).toList();
    final current = children.isNotEmpty ? (_selectedChildForParent[p.id] ?? children.first) : p;
    return CategoryContent(
      key: ValueKey('cat-${current.id}'),
      category: _categoryKey(current),
      initialItems: const [],
      stream: repo.liveByCategory(_categoryKey(current)),
      search: _search,
      offerLink: _offerLink,
      cartKey: _cartKey,
    );
  }

  Widget _buildSubCategoryView(CategoryModel parent, List<CategoryModel> children) {
    final selected = _selectedChildForParent[parent.id];
    return Column(
      children: [
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            final isSelected = selected?.id == child.id;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedChildForParent[parent.id] = child);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.12) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (child.imageUrl != null && child.imageUrl!.isNotEmpty)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: CachedNetworkImage(imageUrl: child.imageUrl!, fit: BoxFit.cover, width: double.infinity),
                        ),
                      )
                    else
                      const Expanded(child: Icon(Icons.local_pizza, size: 36)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        child.nameAr,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Theme.of(context).primaryColor : null),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: selected == null
              ? Center(child: Text('اختر قسمًا من الأعلى'))
              : CategoryContent(
                  key: ValueKey('cat-${selected.id}'),
                  category: _categoryKey(selected),
                  initialItems: const [],
                  stream: repo.liveByCategory(_categoryKey(selected)),
                  search: _search,
                  offerLink: _offerLink,
                  cartKey: _cartKey,
                ),
        ),
      ],
    );
  }

  // (القائمة الجانبية - لم تتغير)
  Widget _buildLuxuryDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final profile = ProfileProvider.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: DeepHeaderClipper(),
                child: Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: (profile.imagePath != null && profile.imagePath!.isNotEmpty)
                              ? FileImage(File(profile.imagePath!))
                              : null,
                          child: (profile.imagePath == null || profile.imagePath!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'أهلنا داقوق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: profile,
                        builder: (context, _) {
                          final displayName = profile.name.isNotEmpty
                              ? profile.name
                              : 'بك';
                          return Text(
                            'مرحباً $displayName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home_rounded,
                  title: 'الرئيسية',
                  onTap: () => Navigator.pop(context),
                  isHighlight: true,
                ),
                const SizedBox(height: 10),
                _buildMenuItem(
                  context,
                  icon: Icons.location_on_rounded,
                  title: 'عنواننا',
                  onTap: () {
                    Navigator.pop(context);
                    showModernSnackBar(context, 'كركوك - داقوق - الشارع العام', icon: Icons.location_on);
                  },
                ),
                const SizedBox(height: 10),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'الإعدادات',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                _buildMenuItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'حول التطبيق',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isHighlight
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isHighlight ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.7) ?? Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isHighlight ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _search.dispose();
    _offerSub?.cancel();
    _offerLink.dispose();
    _catStream?.cancel();
    super.dispose();
  }
}

class DeepHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 70);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 70,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// -----------------------------------------------------------------------------
// Category Page (الصفحة الداخلية)
// -----------------------------------------------------------------------------

class _CategoryPage extends StatefulWidget {
  final String category;
  final List<FoodItem> initialItems;
  final Stream<List<FoodItem>> stream;
  final ValueListenable<String> search;
  final ValueListenable<String?> offerLink;
  final GlobalKey cartKey;

  const _CategoryPage({
    required this.category,
    required this.initialItems,
    required this.stream,
    required this.search,
    required this.offerLink,
    required this.cartKey,
  });

  @override
  State<_CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<_CategoryPage>
    with AutomaticKeepAliveClientMixin {
  late List<FoodItem> _items = widget.initialItems;
  late PageController _pageController;
  double _currentPage = 0.0;
  String _query = '';
  bool _loaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.stream.listen((data) {
      if (mounted) {
        setState(() {
          _items = data;
          _loaded = true;
        });
      }
    });
    _query = widget.search.value;
    widget.search.addListener(() {
      if (mounted) setState(() => _query = widget.search.value);
    });
    _pageController = PageController(viewportFraction: 1.0);
    _currentPage = _pageController.initialPage.toDouble();
    _pageController.addListener(() {
      final p = _pageController.page;
      if (p != null && mounted) setState(() => _currentPage = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final data = _query.isEmpty
        ? _items
        : _items.where((e) {
            final q = _query.toLowerCase();
            return e.name.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q);
          }).toList();

    if (data.isEmpty) {
      if (!_loaded) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(
        child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_query.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = data[index];
          final disabled = !item.isAvailable;
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor, // Changed from Colors.white
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Opacity(
                  opacity: disabled ? 0.45 : 1.0,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: disabled ? Colors.grey : theme.textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                '${item.price % 1 == 0 ? item.price.toInt() : item.price} IQD',
                style: TextStyle(
                  color: disabled ? Colors.grey : theme.primaryColor,
                ),
              ),
              trailing: disabled
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('تم نفاذ الكمية'),
                    )
                  : null,
              onTap: () {
                if (disabled) {
                  showModernSnackBar(context, 'تم نفاذ الكمية ⚠️', color: Colors.grey, icon: Icons.warning_amber_rounded);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailsScreen(item: item)),
                );
              },
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        // 1. ودجت العروض (الآن ديناميكية)
        Positioned(
          top: 15,
          left: 16,
          right: 16,
          height: 130,
          child: _buildOffersSectionDynamic(context, widget.offerLink),
        ),

        // 2. عارض الوجبات (PageView) - لم يتغير
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final dimmed = !item.isAvailable;
              final delta = (index - _currentPage);
              final imageScale = 1.0 - 0.06 * delta.abs();
              final imageTranslate = Offset(delta * 40, -10 * delta);
              final cardTranslate = Offset(0, 24 * delta.abs());

              return Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Center(
                      child: Opacity(
                        opacity: dimmed ? 0.45 : 1.0,
                        child: IgnorePointer(
                          ignoring: dimmed,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(item: item),
                                ),
                              );
                            },
                            child: Transform.translate(
                              offset: imageTranslate,
                              child: Transform.scale(
                                scale: imageScale.clamp(0.85, 1.0),
                                child: Hero(
                                  tag: item.id,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.62,
                                    height:
                                        MediaQuery.of(context).size.width *
                                        0.62,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    _buildBottomDetailCard(
                      context,
                      item,
                      dimmed,
                      theme,
                      cardTranslate,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDetailCard(
    BuildContext context,
    FoodItem item,
    bool dimmed,
    ThemeData theme,
    Offset cardTranslate,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: cardTranslate,
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price % 1 == 0 ? item.price.toInt() : item.price} IQD',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor:
                          dimmed ? Colors.grey : theme.primaryColor,
                      child: Builder(
                        builder: (btnContext) {
                          return IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: dimmed
                                ? () {
                                    showModernSnackBar(context, 'تم نفاذ الكمية ⚠️', color: Colors.grey, icon: Icons.warning_amber_rounded);
                                  }
                                : () async {
                                    final connectivityResult = await Connectivity().checkConnectivity();
                                    if (connectivityResult.contains(ConnectivityResult.none)) {
                                      showModernSnackBar(context, 'يرجى التحقق من اتصال الإنترنت للطلب 🌐', color: Colors.redAccent, icon: Icons.wifi_off);
                                      return;
                                    }
                                    
                                    FlyAnimation.run(
                                      context,
                                      cartKey: widget.cartKey,
                                      buttonContext: btnContext,
                                      imageUrl: item.imageUrl,
                                      onComplete: () {
                                        CartProvider.of(context).add(item);
                                      },
                                    );
                                  },
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffersSectionDynamic(
    BuildContext context,
    ValueListenable<String?> linkController,
  ) {
    final theme = Theme.of(context);

    // هذا الكونتينر الخارجي يحدد الإطار والظل - دائماً مرئي
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: linkController,
        builder: (context, link, _) {
          bool hasValidLink = false;
          if (link != null && link.isNotEmpty) {
            final lower = link.toLowerCase();
            hasValidLink =
                lower.endsWith('.png') ||
                lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.webp');
          }

          if (!hasValidLink) {
            return _buildPlaceholderWidget(theme);
          }

          // أظهر الصورة إذا كانت صالحة
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: link!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (context, url, error) {
                return _buildPlaceholderWidget(theme);
              },
              placeholder: (context, url) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildPlaceholderWidget(theme),
                    Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ودجت الشكل الافتراضي (في حال عدم وجود صورة)
  Widget _buildPlaceholderWidget(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_rounded,
              color: theme.primaryColor,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              "مساحة العروض الحصرية",
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "قريباً...",
              style: TextStyle(
                color: theme.primaryColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
