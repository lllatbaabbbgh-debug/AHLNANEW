import 'package:flutter/material.dart';
import 'dart:async';
import '../../admin/core/admin_data.dart';
import '../models/order.dart';
import '../../core/repos/order_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class AdminHomeScreen extends StatefulWidget {
  final bool restrictActions;
  final bool compactMobile;
  const AdminHomeScreen({
    super.key,
    this.restrictActions = false,
    this.compactMobile = false,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final repo = OrderRepository();
  final data = AdminData();
  List<Order> orders = [];
  Stream<List<Order>>? _stream;
  StreamSubscription<List<Order>>? _sub;

  // ألوان التصميم
  final primaryColor = const Color(0xFF23AA49);
  final bgGrey = const Color(0xFFF6F7F9);

  String _typeLabel(String? t) {
    switch (t) {
      case 'takeaway':
        return 'سفري';
      case 'dinein':
        return 'صالة';
      case 'delivery':
        return 'توصيل';
      default:
        return t ?? 'عام';
    }
  }

  Color _typeColor(String? t) {
    switch (t) {
      case 'takeaway':
        return Colors.orange;
      case 'dinein':
        return Colors.blue;
      case 'delivery':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _stream = repo.liveActiveOrders();
    _sub = _stream!.listen((list) {
      if (mounted) {
        setState(() => orders = list);
      }
    });
  }

  Future<void> _loadOrders() async {
    final list = await repo.fetchActiveOrders();
    setState(() => orders = list);
  }

  // الدوال المنطقية (نفسها لم تتغير)
  void _approve(int idx) async {
    final id = orders[idx].id;
    try {
      await repo.setStatus(id, 'cooking');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('جاري التحضير 👨‍🍳')));
      }
    } catch (e) {
      /*...*/
    } finally {
      await _loadOrders();
    }
  }

  void _cancel(int idx) async {
    final id = orders[idx].id;
    try {
      await repo.deleteOrder(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الإلغاء ❌')));
      }
    } catch (e) {
      /*...*/
    } finally {
      await _loadOrders();
    }
  }

  void _complete(int idx) async {
    final id = orders[idx].id;
    try {
      await repo.setStatus(id, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تسليم الطلب ✅')));
      }
    } catch (e) {
      /*...*/
    } finally {
      await _loadOrders();
    }
  }

  Future<void> _track(Order o) async {
    final lat = o.customerLat;
    final long = o.customerLong;
    if (lat == null || long == null) return;
    final latStr = lat.toStringAsFixed(6).replaceAll(',', '.');
    final longStr = long.toStringAsFixed(6).replaceAll(',', '.');
    if (Platform.isAndroid) {
      final gmNav = Uri.parse('google.navigation:q=$latStr,$longStr&mode=d');
      final gmWeb = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latStr,$longStr&travelmode=driving',
      );
      final canMapsApp = await canLaunchUrl(gmNav);
      await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.map_rounded, color: Colors.blue),
                  title: const Text('فتح عبر تطبيق الخرائط'),
                  subtitle: Text(
                    canMapsApp ? 'Google Maps' : 'غير متاح على الجهاز',
                  ),
                  enabled: canMapsApp,
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await launchUrl(
                        gmNav,
                        mode: LaunchMode.externalApplication,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم فتح الملاحة')),
                        );
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر فتح تطبيق الخرائط'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.public, color: Colors.green),
                  title: const Text('فتح عبر المتصفح'),
                  subtitle: const Text('Google Maps Web'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await launchUrl(
                        gmWeb,
                        mode: LaunchMode.externalApplication,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم فتح الملاحة')),
                        );
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تعذر فتح المتصفح')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    final googleSearch = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latStr,$longStr',
    );
    final googleAt = Uri.parse(
      'https://www.google.com/maps/@$latStr,$longStr,16z',
    );
    final googleDir = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=$latStr,$longStr&travelmode=driving',
    );
    final bingWeb = Uri.parse(
      'https://bing.com/maps/default.aspx?cp=$latStr~$longStr&lvl=16&style=r',
    );
    final bingCp = Uri.parse('bingmaps:?cp=$latStr~$longStr');
    final bingPos = Uri.parse('bingmaps:?rtp=~pos.${latStr}_$longStr');

    for (final uri in [
      googleDir,
      googleSearch,
      googleAt,
      bingWeb,
      bingCp,
      bingPos,
    ]) {
      if (await canLaunchUrl(uri)) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم فتح الملاحة')));
        }
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح تطبيق الخرائط')));
    }
  }

  void _showDetails(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _OrderDetailsScreen(order: order, primaryColor: primaryColor),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              "لا توجد طلبات نشطة حالياً",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgGrey,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            double childAspectRatio = 1.0;
            if (!widget.compactMobile) {
              if (constraints.maxWidth > 1400) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 1000) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 700) {
                crossAxisCount = 2;
              }
              childAspectRatio = 1.05;
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final o = orders[index];
                return _buildOrderTicket(o, index);
              },
            );
          },
        ),
      ),
    );
  }

  // 🎫 تصميم بطاقة الطلب (شكل تذكرة Kiosk)
  Widget _buildOrderTicket(Order o, int index) {
    final typeColor = _typeColor(o.orderType);
    final isCooking = o.status == OrderStatus.cooking;
    final isIOS = Platform.isIOS;

    // Debug: عرض الإحداثيات في وحدة التحكم
    print(
      'طلب ${o.id}: نوع=${o.orderType}, lat=${o.customerLat}, long=${o.customerLong}',
    );

    if (widget.compactMobile) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isCooking ? Border.all(color: primaryColor, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel(o.orderType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '#${o.id.substring(0, 6)}',
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      o.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDetails(o),
                    icon: const Icon(Icons.info_outline, size: 18),
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'تفاصيل الزبون',
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${o.totalPrice % 1 == 0 ? o.totalPrice.toInt() : o.totalPrice} IQD',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: isIOS ? 15 : 16,
                    ),
                  ),
                  if (o.customerLat != null && o.customerLong != null)
                    ElevatedButton.icon(
                      onPressed: () => _track(o),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.location_on_rounded, size: 18),
                      label: const Text('تتبع', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isIOS)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: widget.restrictActions
                            ? null
                            : () => _cancel(index),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'رفض',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.restrictActions
                            ? null
                            : (isCooking
                                  ? () => _complete(index)
                                  : () => _approve(index)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCooking
                              ? Colors.blueAccent
                              : primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          isCooking ? 'إكمال' : 'قبول',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isCooking ? Border.all(color: primaryColor, width: 2) : null,
      ),
      child: Column(
        children: [
          // 1. رأس البطاقة (نوع الطلب + الوقت/الرقم)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(o.orderType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '#${o.id.substring(0, 6)}', // رقم مختصر
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // 2. جسم البطاقة (العناصر)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الزبون
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          o.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        color: Colors.grey,
                        onPressed: () => _showDetails(o),
                        tooltip: 'تفاصيل الزبون',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // قائمة العناصر (Scrollable)
                  Expanded(
                    child: ListView.separated(
                      itemCount: o.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = o.items[i];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. ذيل البطاقة (السعر + الأزرار)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Column(
              children: [
                // السعر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    Text(
                      '${o.totalPrice % 1 == 0 ? o.totalPrice.toInt() : o.totalPrice} IQD',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (o.customerLat != null && o.customerLong != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _track(o),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.location_on_rounded),
                        label: const Text('🗺️ تتبع موقع الزبون'),
                      ),
                    ),
                  )
                else if (o.orderType == 'delivery')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لا يوجد موقع لهذا الطلب',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // الأزرار التفاعلية
                if (!isIOS)
                  !isCooking
                      ? Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: widget.restrictActions
                                    ? null
                                    : () => _cancel(index),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text("رفض"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.restrictActions
                                    ? null
                                    : () => _approve(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text("قبول وبدء"),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.restrictActions
                                ? null
                                : () => _complete(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.blueAccent.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text("إكمال الطلب"),
                          ),
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class _OrderDetailsScreen extends StatelessWidget {
  final Order order;
  final Color primaryColor;
  const _OrderDetailsScreen({required this.order, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(order.phone),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(order.address)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'العناصر',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.item.name)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع'),
                  Text(
                    '${order.totalPrice % 1 == 0 ? order.totalPrice.toInt() : order.totalPrice} IQD',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
