import 'package:flutter/material.dart';
import '../core/cart.dart';
import '../core/storage.dart';
import '../core/repos/order_repository.dart';
import '../admin/models/order.dart';
import '../core/profile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
                        subtitle: Text('${item.item.price % 1 == 0 ? item.item.price.toInt() : item.item.price} IQD'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => cart.removeOne(item.item.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () => cart.add(item.item),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => cart.removeAll(item.item.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cs.surface),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع: ${cart.totalPrice % 1 == 0 ? cart.totalPrice.toInt() : cart.totalPrice} IQD',
                        style: Theme.of(context).textTheme.headlineSmall),
                    ElevatedButton(onPressed: () async {
                      final profile = ProfileProvider.of(context);
                      if (profile.name.isEmpty || profile.phone.isEmpty || profile.address.isEmpty) {
                        final local = await Storage.loadProfile();
                        profile.set(name: local['name'], phone: local['phone'], address: local['address']);
                      }
                      final type = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final cs = Theme.of(context).colorScheme;
                          String? selected;
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                backgroundColor: cs.surface,
                                title: const Text('اختيار نوع الطلب'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RadioListTile<String>(
                                      title: const Text('سفري'),
                                      value: 'takeaway',
                                      groupValue: selected,
                                      onChanged: (v) => setState(() => selected = v),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('صالة'),
                                      value: 'dinein',
                                      groupValue: selected,
                                      onChanged: (v) => setState(() => selected = v),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('دليفري'),
                                      value: 'delivery',
                                      groupValue: selected,
                                      onChanged: (v) => setState(() => selected = v),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                                  ElevatedButton(
                                    onPressed: selected == null ? null : () => Navigator.pop(context, selected),
                                    child: const Text('إتمام الطلب'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      if (type == null) return;
                      final repo = OrderRepository();
                      final items = cart.items
                          .map((ci) => OrderItem(item: ci.item, quantity: ci.quantity))
                          .toList();
                      final name = profile.name.isNotEmpty ? profile.name : 'زبون';
                      final phone = profile.phone.isNotEmpty ? profile.phone : '0770';
                      final address = profile.address.isNotEmpty ? profile.address : 'بدون';
                      String? orderId;
                      try {
                        print('Attempting to create order with:');
                        print('Name: $name, Phone: $phone, Address: $address, Type: $type');
                        print('Items count: ${items.length}');
                        orderId = await repo.createOrder(
                          customerName: name,
                          phone: phone,
                          address: address,
                          orderType: type,
                          items: items,
                        );
                        print('Order creation result: $orderId');
                      } catch (e, stackTrace) {
                        print('Order submission error in cart: $e');
                        print('Stack trace: $stackTrace');
                        orderId = null;
                      }
                      if (orderId == null) {
                        if (!context.mounted) return;
                        final overlay = Overlay.of(context);
                        final entry = OverlayEntry(
                          builder: (_) => Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('تعذر إرسال الطلب', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                        overlay.insert(entry);
                        await Future.delayed(const Duration(seconds: 1));
                        entry.remove();
                        return;
                      }
                      cart.clear();
                      if (!context.mounted) return;
                      final overlay = Overlay.of(context);
                      final entry = OverlayEntry(
                        builder: (_) => Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('تم إرسال الطلب', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                      overlay.insert(entry);
                      await Future.delayed(const Duration(seconds: 1));
                      entry.remove();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }, child: const Text('إتمام الطلب')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
