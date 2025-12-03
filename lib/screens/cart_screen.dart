import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import '../core/cart.dart';
import '../core/storage.dart';
import '../core/repos/order_repository.dart';
import '../admin/models/order.dart';
import '../core/profile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showToastNotification(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ToastWidget(
            message: message,
            isError: isError,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        actions: [
          TextButton(
            onPressed: cart.items.isEmpty ? null : cart.clear,
            child: const Text('تفريغ'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('السلة فارغة'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.item.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.black26,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        title: Text(item.item.name),
                        subtitle: Text(
                          '${item.item.price % 1 == 0 ? item.item.price.toInt() : item.item.price} IQD',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => cart.removeOne(item.item.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (!item.item.isAvailable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نفاذ الكمية')),
                                  );
                                  return;
                                }
                                cart.add(item.item);
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => cart.removeAll(item.item.id),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجمالي الكلي',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            '${cart.totalPrice % 1 == 0 ? cart.totalPrice.toInt() : cart.totalPrice} IQD',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          onPressed: () async {
                            final profile = ProfileProvider.of(context);
                            if (profile.name.isEmpty ||
                                profile.phone.isEmpty ||
                                profile.address.isEmpty) {
                              final local = await Storage.loadProfile();
                              profile.set(
                                name: local['name'],
                                phone: local['phone'],
                                address: local['address'],
                              );
                            }

                            // ----------------------------------------------------
                            //  🔥 بداية نافذة الاختيار الجديدة (Premium Design) 🔥
                            // ----------------------------------------------------
                            final type = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                final theme = Theme.of(context);
                                String? selected;
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return Dialog(
                                      backgroundColor: Colors
                                          .transparent, // شفاف لنرسم نحن الخلفية
                                      insetPadding: const EdgeInsets.all(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.scaffoldBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            28,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          24,
                                          20,
                                          20,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'شلون تحب تستلم طلبك؟',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                            const SizedBox(height: 24),

                                            // خيار سفري
                                            _buildPremiumCard(
                                              context,
                                              title: 'سفري (Takeaway)',
                                              value: 'takeaway',
                                              groupValue: selected,
                                              icon: Icons.shopping_bag_rounded,
                                              onChanged: (v) =>
                                                  setState(() => selected = v),
                                            ),
                                            const SizedBox(height: 12),

                                            // خيار صالة
                                            _buildPremiumCard(
                                              context,
                                              title: 'داخل المطعم (Dine-in)',
                                              value: 'dinein',
                                              groupValue: selected,
                                              icon: Icons.table_bar_rounded,
                                              onChanged: (v) =>
                                                  setState(() => selected = v),
                                            ),
                                            const SizedBox(height: 12),

                                            // خيار دليفري
                                            _buildPremiumCard(
                                              context,
                                              title: 'توصيل (Delivery)',
                                              value: 'delivery',
                                              groupValue: selected,
                                              icon:
                                                  Icons.delivery_dining_rounded,
                                              onChanged: (v) =>
                                                  setState(() => selected = v),
                                            ),
                                            const SizedBox(height: 30),

                                            // أزرار التحكم
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'إلغاء',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 2,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          selected != null
                                                          ? theme.primaryColor
                                                          : Colors.grey[300],
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                      elevation:
                                                          selected != null
                                                          ? 8
                                                          : 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: selected == null
                                                        ? null
                                                        : () => Navigator.pop(
                                                            context,
                                                            selected,
                                                          ),
                                                    child: const Text(
                                                      'تأكيد الطلب',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                            // ----------------------------------------------------
                            // نهاية التصميم الجديد
                            // ----------------------------------------------------

                            if (type == null) return;

                            // إظهار رسالة للمستخدم حول نوع الطلب المختار
                            _showToastNotification(
                              context,
                              'تم اختيار طلب ${type == 'delivery'
                                  ? 'توصيل'
                                  : type == 'takeaway'
                                  ? 'سفري'
                                  : 'داخل المطعم'}',
                              isError: false,
                            );

                            final repo = OrderRepository();
                            final items = cart.items
                                .map(
                                  (ci) => OrderItem(
                                    item: ci.item,
                                    quantity: ci.quantity,
                                  ),
                                )
                                .toList();
                            final name = profile.name.isNotEmpty
                                ? profile.name
                                : 'زبون';
                            final phone = profile.phone.isNotEmpty
                                ? profile.phone
                                : '0770';
                            final address = profile.address.isNotEmpty
                                ? profile.address
                                : 'بدون';
                            String? orderId;
                            try {
                              double? lat;
                              double? long;
                              if (type == 'delivery') {
                                _showToastNotification(
                                  context,
                                  'جاري الحصول على موقعك للتوصيل...',
                                  isError: false,
                                );

                                var serviceEnabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!serviceEnabled) {
                                  final accept =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('تشغيل الموقع'),
                                          content: const Text(
                                            'يرجى تشغيل الـ GPS لإتمام طلب التوصيل. هل تريد فتح الإعدادات؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('لا'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('نعم'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (accept) {
                                    await Geolocator.openLocationSettings();
                                    serviceEnabled =
                                        await Geolocator.isLocationServiceEnabled();
                                    if (!serviceEnabled) {
                                      _showToastNotification(
                                        context,
                                        'قم بتشغيل الموقع',
                                        isError: true,
                                      );
                                      return;
                                    }
                                  } else {
                                    _showToastNotification(
                                      context,
                                      'قم بتشغيل الموقع',
                                      isError: true,
                                    );
                                    return;
                                  }
                                }
                                var permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                }
                                if (permission ==
                                    LocationPermission.deniedForever) {
                                  final goSettings =
                                      await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'صلاحية الموقع مطلوبة',
                                          ),
                                          content: const Text(
                                            'يجب منح صلاحية الوصول للموقع. هل تريد فتح إعدادات التطبيق؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('لا'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'فتح الإعدادات',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (goSettings) {
                                    await Geolocator.openAppSettings();
                                  }
                                  _showToastNotification(
                                    context,
                                    'قم بتفعيل صلاحية الموقع',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (permission == LocationPermission.denied) {
                                  _showToastNotification(
                                    context,
                                    'صلاحية الموقع مطلوبة لطلب التوصيل',
                                    isError: true,
                                  );
                                  return;
                                }
                                Position pos;
                                if (Platform.isAndroid) {
                                  try {
                                    pos =
                                        await Geolocator.getPositionStream(
                                          locationSettings: AndroidSettings(
                                            accuracy: LocationAccuracy
                                                .bestForNavigation,
                                            forceLocationManager: true,
                                            distanceFilter: 0,
                                            intervalDuration: Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        ).first.timeout(
                                          const Duration(seconds: 10),
                                        );
                                  } catch (_) {
                                    pos = await Geolocator.getCurrentPosition(
                                      desiredAccuracy:
                                          LocationAccuracy.bestForNavigation,
                                      timeLimit: const Duration(seconds: 10),
                                    );
                                  }
                                } else {
                                  pos = await Geolocator.getCurrentPosition(
                                    desiredAccuracy:
                                        LocationAccuracy.bestForNavigation,
                                    timeLimit: const Duration(seconds: 10),
                                  );
                                }
                                lat = pos.latitude;
                                long = pos.longitude;

                                _showToastNotification(
                                  context,
                                  'تم الحصول على الموقع بنجاح: ${lat.toStringAsFixed(4)}, ${long.toStringAsFixed(4)}',
                                  isError: false,
                                );
                              }
                              orderId = await repo.createOrder(
                                customerName: name,
                                phone: phone,
                                address: address,
                                orderType: type,
                                items: items,
                                customerLat: lat,
                                customerLong: long,
                              );
                            } catch (e) {
                              orderId = null;
                            }
                            if (orderId == null) {
                              if (!context.mounted) return;
                              _showToastNotification(
                                context,
                                'تعذر إرسال الطلب',
                                isError: true,
                              );
                              return;
                            }
                            cart.clear();
                            if (!context.mounted) return;
                            _showToastNotification(
                              context,
                              'تم إرسال الطلب',
                              isError: false,
                            );
                            await Future.delayed(const Duration(seconds: 2));
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'إتمام الطلب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔥 ودجت البطاقة الفاخرة (Premium Card) 🔥
  Widget _buildPremiumCard(
    BuildContext context, {
    required String title,
    required String value,
    required String? groupValue,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // الأيقونة داخل دائرة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            // النص
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            // علامة الاختيار
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isError ? Colors.redAccent : Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isError ? Icons.error_outline : Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
