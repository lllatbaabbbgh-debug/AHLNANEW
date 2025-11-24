import 'package:flutter/material.dart';
import 'dart:async';
import '../../admin/core/admin_data.dart';
import '../models/order.dart';
import '../../core/repos/order_repository.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final repo = OrderRepository();
  final data = AdminData();
  List<Order> orders = [];
  Stream<List<Order>>? _stream;
  StreamSubscription<List<Order>>? _sub;

  String _typeLabel(String? t) {
    switch (t) {
      case 'takeaway':
        return 'سفري';
      case 'dinein':
        return 'صالة';
      case 'delivery':
        return 'دليفري';
      default:
        return t ?? '';
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

  void _approve(int idx) async {
    final id = orders[idx].id;
    await repo.setStatus(id, 'cooking');
    await _loadOrders();
  }

  void _cancel(int idx) async {
    final id = orders[idx].id;
    await repo.deleteOrder(id);
    await _loadOrders();
  }

  void _complete(int idx) async {
    final id = orders[idx].id;
    try {
      await repo.setStatus(id, 'completed');
      print('✅ Order $id marked completed');
    } catch (e) {
      print('❌ Failed to complete order $id: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الإكمال: $e')));
    } finally {
      await _loadOrders();
    }
  }

  void _showDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text('تفاصيل ${order.id}'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الاسم: ${order.customerName}'),
                Text('الهاتف: ${order.phone}'),
                Text('العنوان: ${order.address}'),
                if (order.orderType != null && order.orderType!.isNotEmpty)
                  Text('نوع الطلب: ${_typeLabel(order.orderType)}'),
                const SizedBox(height: 12),
                Text('العناصر:'),
                const SizedBox(height: 8),
                ...order.items.map(
                  (oi) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(oi.item.name),
                      Text('x${oi.quantity}'),
                      Text(
                        '${((oi.item.price * oi.quantity) % 1 == 0 ? (oi.item.price * oi.quantity).toInt() : (oi.item.price * oi.quantity))} IQD',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'المجموع: ${order.totalPrice % 1 == 0 ? order.totalPrice.toInt() : order.totalPrice} IQD',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final o = orders[index];
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.id, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (o.orderType != null)
                  Text('نوع الطلب: ${_typeLabel(o.orderType)}'),
                const SizedBox(height: 8),
                Text(
                  'المجموع: ${o.totalPrice % 1 == 0 ? o.totalPrice.toInt() : o.totalPrice} IQD',
                ),
                const SizedBox(height: 8),
                Text(
                  'الحالة: ${o.status == OrderStatus.pending
                      ? 'بانتظار'
                      : o.status == OrderStatus.cooking
                      ? 'قيد التحضير'
                      : 'مكتمل'}',
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showDetails(o),
                        child: const Text('تفاصيل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approve(index),
                        child: const Text('بدء التحضير'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _cancel(index),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _complete(index),
                        child: const Text('إكمال'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
