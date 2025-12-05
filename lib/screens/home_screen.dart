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
import 'cart_screen.dart';
import '../core/repos/food_repository.dart';
import '../core/repos/offers_repository.dart';
import '../core/ui_utils.dart';
import '../core/animations/fly_animation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final repo = FoodRepository();
  bool _prefetched = false;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _search = ValueNotifier<String>('');

  static const List<String> _categories = ['Lahm Bi Ajeen', 'Pizza', 'Drinks'];
  static const Map<String, String> _categoryAr = {
    'Lahm Bi Ajeen': 'لحم بعجين',
    'Pizza': 'بيتزا',
    'Drinks': 'مشروبات',
  };

  List<Widget> _pages = const [];
  late TabController _tabController;

  final ValueNotifier<String?> _offerLink = ValueNotifier<String?>(null);
  final _offersRepo = OffersRepository();
  StreamSubscription<String?>? _offerSub;
  final GlobalKey _cartKey = GlobalKey();
  final Box _offersBox = Hive.box('offers_cache');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    // تهيئة صفحات فارغة بسرعة
    final builtPages = <Widget>[];
    for (final c in _categories) {
      builtPages.add(
        _CategoryPage(
          key: ValueKey<String>('boot-$c'),
          category: c,
          initialItems: const <FoodItem>[],
          stream: repo.liveByCategory(c),
          search: _search,
          offerLink: _offerLink,
          cartKey: _cartKey,
        ),
      );
    }
    _pages = builtPages;
    _initializeApp();
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

  Future<void> _prefetchAll() async {
    try {
      final futures = _categories.map((c) async {
        try {
          final items = await repo
              .fetchByCategory(c)
              .timeout(const Duration(seconds: 10));
          print(
            '✅ تم تحميل قسم ${_categoryAr[c]} بنجاح مع ${items.length} عنصر',
          );
          return _CategoryPage(
            key: ValueKey<String>(c),
            category: c,
            initialItems: items,
            stream: repo.liveByCategory(c),
            search: _search,
            offerLink: _offerLink,
            cartKey: _cartKey,
          );
        } catch (e) {
          print('⚠️ خطأ في تحميل قسم $c: $e');
          return _CategoryPage(
            key: ValueKey<String>(c),
            category: c,
            initialItems: const [],
            stream: const Stream<List<FoodItem>>.empty(),
            search: _search,
            offerLink: _offerLink,
            cartKey: _cartKey,
          );
        }
      }).toList();

      final builtPages = await Future.wait(futures);
      _pages = builtPages;
      if (mounted) {
        setState(() => _prefetched = true);
        print('✅ تم تحميل جميع الأقسام بالتوازي بنجاح');
      }
    } catch (e) {
      print('❌ خطأ عام في تحميل الأقسام: $e');
      if (mounted) {
        setState(() => _prefetched = true); // ننهي التحميل حتى لو حدث خطأ
      }
    }
  }

  Stream<List<FoodItem>> _streamByCategory(String c) => repo.liveByCategory(c);

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      drawerScrimColor: Colors.transparent,
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,

        // --- حقل البحث ---
        title: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _search.value = v.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'بحث',
                hintStyle: TextStyle(color: Colors.grey[400]),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _search,
                  builder: (context, q, _) {
                    if (q.isEmpty) return const SizedBox.shrink();
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
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
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
                      color: hasItems ? theme.primaryColor : Colors.black87,
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
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.black87,
                size: 30,
              ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],

        // --- التبويبات ---
        bottom: TabBar(
          controller: _tabController,
          tabs: _categories.map((c) => Tab(text: _categoryAr[c])).toList(),
          labelPadding: const EdgeInsets.symmetric(vertical: 10),
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          onTap: (index) {},
        ),
      ),

      endDrawer: _buildLuxuryDrawer(context),

      body: TabBarView(controller: _tabController, children: _pages),
    );
  }

  // (القائمة الجانبية - لم تتغير)
  Widget _buildLuxuryDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final profile = ProfileProvider.of(context);

    return Drawer(
      backgroundColor: Colors.white,
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
                        child: const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 45,
                            color: Colors.grey,
                          ),
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
                  onTap: () => Navigator.pop(context),
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
          color: isHighlight ? theme.primaryColor : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isHighlight ? theme.primaryColor : Colors.black87,
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
    _tabController.dispose();
    _searchController.dispose();
    _search.dispose();
    _offerSub?.cancel();
    _offerLink.dispose();
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
    super.key,
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
              color: Colors.white,
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
                  color: disabled ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: Text(
                '${item.price} IQD',
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
              color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.black87,
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
                    color: Colors.grey[600],
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
        color: Colors.white,
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
