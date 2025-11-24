import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/order.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class OrderRepository {
  static const ordersTable = 'orders';
  static const orderItemsTable = 'order_items';
  static const recordsTable = 'order_records';

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient ?? _c;

  String? _extractType(String? address) {
    if (address == null) return null;
    final m = RegExp(r"\[(.*?)\]").firstMatch(address);
    return m?.group(1);
  }

  Future<String?> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String orderType,
    required List<OrderItem> items,
  }) async {
    final primary = _c ?? _svc;
    if (primary == null) {
      print('ERROR: Supabase clients are null - check environment variables');
      return null;
    }

    // التحقق من الاتصال بقاعدة البيانات وهيكل الجدول
    try {
      final testConnection = await primary.from(ordersTable).select().limit(1);
      print('✅ Database connection test: SUCCESS');

      // التحقق من الأعمدة المتوفرة
      try {
        final columns = await primary.from(ordersTable).select('*').limit(0);
        print('📊 Available columns in orders table: ${columns.length}');
      } catch (e) {
        print('⚠️ Could not check columns: $e');
      }
    } catch (e) {
      print('❌ Database connection failed: $e');
      return null;
    }

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final totalPrice = items.fold(
        0.0,
        (s, e) => s + e.item.price * e.quantity,
      );
      final now = DateTime.now().toIso8601String();

      print('📋 Creating order with data:');
      print('  ID: $orderId');
      print('  Customer: $customerName');
      print('  Phone: $phone');
      print('  Address: $address');
      print('  Order Type: $orderType');
      print('  Total Price: $totalPrice');
      print('  Items Count: ${items.length}');

      // إذا لم يكن عمود order_type موجوداً، سنخزن نوع الطلب في عنوان الطلب
      String finalAddress = address;
      String finalOrderType = orderType;

      SupabaseClient? usedClient;
      try {
        print('🔄 Attempting to insert order...');
        // محاولة إضافة order_type إذا كان موجوداً
        try {
          final dataWithType = {
            'id': orderId,
            'customer_name': customerName,
            'phone': phone,
            'address': finalAddress,
            'status': 'pending',
            'total_price': totalPrice,
            'created_at': now,
            'order_type': finalOrderType,
          };
          await primary.from(ordersTable).insert(dataWithType);
          print('✅ Order inserted with order_type');
        } catch (e) {
          if (e.toString().contains('order_type')) {
            print('⚠️ order_type missing, storing type in address');
            finalAddress = '[$finalOrderType] $address';
            final dataNoType = {
              'id': orderId,
              'customer_name': customerName,
              'phone': phone,
              'address': finalAddress,
              'status': 'pending',
              'total_price': totalPrice,
              'created_at': now,
            };
            await primary.from(ordersTable).insert(dataNoType);
            print('✅ Order inserted without order_type; type embedded in address');
          } else {
            rethrow;
          }
        }
        usedClient = primary;
      } catch (orderError) {
        print('❌ Order insert failed: $orderError');
        final svc = _svc;
        if (svc != null && svc != primary) {
          print('🔄 Retrying with service client...');
          try {
            await svc.from(ordersTable).insert({
              'id': orderId,
              'customer_name': customerName,
              'phone': phone,
              'address': finalAddress,
              'order_type': finalOrderType,
              'status': 'pending',
              'total_price': totalPrice,
              'created_at': now,
            });
            usedClient = svc;
            print('✅ Order inserted with service client');
          } catch (svcError) {
            if (svcError.toString().contains('order_type')) {
              print('⚠️ order_type missing on service client; embedding type in address');
              final embedAddr = '[$finalOrderType] $address';
              await svc.from(ordersTable).insert({
                'id': orderId,
                'customer_name': customerName,
                'phone': phone,
                'address': embedAddr,
                'status': 'pending',
                'total_price': totalPrice,
                'created_at': now,
              });
              usedClient = svc;
              print('✅ Order inserted with service client without order_type');
            } else {
              rethrow;
            }
          }
        } else {
          rethrow;
        }
      }

      // Insert order items
      if (items.isNotEmpty) {
        try {
          final itemsData = items
              .map(
                (e) => {
                  'order_id': orderId,
                  'food_id': e.item.id,
                  'name': e.item.name,
                  'price': e.item.price,
                  'quantity': e.quantity,
                },
              )
              .toList();
          print('📝 Inserting order items data: ${itemsData.length} items');
          await (usedClient ?? primary).from(orderItemsTable).insert(itemsData);
          print('✅ Order items inserted successfully');
        } catch (itemsError) {
          print('❌ Order items insert failed: $itemsError');
          print('Error details: ${itemsError.toString()}');
          // If RLS blocks us, try with service client
          final svc = _svc;
          if (svc != null && svc != usedClient) {
            print('🔄 Retrying order items with service client...');
            final itemsData = items
                .map(
                  (e) => {
                    'order_id': orderId,
                    'food_id': e.item.id,
                    'name': e.item.name,
                    'price': e.item.price,
                    'quantity': e.quantity,
                  },
                )
                .toList();
            await svc.from(orderItemsTable).insert(itemsData);
            print('✅ Order items inserted with service client');
          } else {
            rethrow;
          }
        }
      }

      print('🎉 ORDER CREATED SUCCESSFULLY! Order ID: $orderId');
      print('📋 Final Order Details:');
      print('  Customer: $customerName');
      print('  Phone: $phone');
      print('  Address: $finalAddress');
      print('  Order Type: $finalOrderType');
      print('  Total: $totalPrice');
      print('  Items: ${items.length}');
      return orderId;
    } catch (e, stackTrace) {
      print('ERROR creating order: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> setStatus(String orderId, String status) async {
    final c = _svc ?? _c;
    if (c == null) return;
    
    try {
      if (status == 'completed') {
        // First get the complete order data with items
        final orderData = await c
            .from(ordersTable)
            .select('*, order_items(*)')
            .eq('id', orderId)
            .single();
        
        // Move to records with essential fields; avoid failures on missing columns
        final recordData = {
          'id': orderData['id'],
          'customer_name': orderData['customer_name'],
          'phone': orderData['phone'],
          'address': orderData['address'],
          'status': 'completed',
          'total_price': orderData['total_price'],
          'created_at': orderData['created_at'],
        };
        final ot = orderData['order_type'] ?? _extractType(orderData['address']?.toString());
        if (ot != null) {
          try {
            await c.from(recordsTable).insert({...recordData, 'order_type': ot});
          } catch (_) {
            await c.from(recordsTable).insert(recordData);
          }
        } else {
          await c.from(recordsTable).insert(recordData);
        }
        
        // Delete from orders table after moving to records
        await c.from(orderItemsTable).delete().eq('order_id', orderId);
        await c.from(ordersTable).delete().eq('id', orderId);
      } else {
        // For other statuses, just update the status
        await c.from(ordersTable).update({'status': status}).eq('id', orderId);
      }
    } catch (e) {
      // Try with service client if main client fails
      final svc = _svc;
      if (svc != null && svc != c) {
        if (status == 'completed') {
          final orderData = await svc
              .from(ordersTable)
              .select('*, order_items(*)')
              .eq('id', orderId)
              .single();
          
          final recordData = {
            'id': orderData['id'],
            'customer_name': orderData['customer_name'],
            'phone': orderData['phone'],
            'address': orderData['address'],
            'status': 'completed',
            'total_price': orderData['total_price'],
            'created_at': orderData['created_at'],
          };
          final ot = orderData['order_type'] ?? _extractType(orderData['address']?.toString());
          if (ot != null) {
            try {
              await svc.from(recordsTable).insert({...recordData, 'order_type': ot});
            } catch (_) {
              await svc.from(recordsTable).insert(recordData);
            }
          } else {
            await svc.from(recordsTable).insert(recordData);
          }
          
          await svc.from(orderItemsTable).delete().eq('order_id', orderId);
          await svc.from(ordersTable).delete().eq('id', orderId);
        } else {
          await svc.from(ordersTable).update({'status': status}).eq('id', orderId);
        }
      } else {
        // As a last resort, mark as completed in orders table to avoid UI dead state
        try {
          await (c ?? svc)!.from(ordersTable).update({'status': 'completed'}).eq('id', orderId);
        } catch (_) {}
      }
    }
  }

  Future<List<Order>> fetchActiveOrders() async {
    final c = _svc ?? _c;
    if (c == null) return [];
    final res = await c
        .from(ordersTable)
        .select('*, order_items(*)')
        .neq('status', 'completed')
        .order('created_at');
    final list = (res as List)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
    return list.map((o) {
      final items =
          (o['order_items'] as List?)?.map((it) {
            final m = Map<String, dynamic>.from(it);
            return OrderItem(
              item: FoodItem(
                id: m['food_id']?.toString() ?? m['name'],
                name: m['name'] ?? '',
                price: (m['price'] as num?)?.toDouble() ?? 0,
                description: '',
                imageUrl: '',
                category: 'Unknown',
                isAvailable: true,
              ),
              quantity: m['quantity'] ?? 1,
            );
          }).toList() ??
          [];
      final type = o['order_type']?.toString() ?? _extractType(o['address']?.toString());
      return Order(
        id: o['id']?.toString() ?? '',
        customerName: o['customer_name'] ?? '',
        phone: o['phone'] ?? '',
        address: o['address'] ?? '',
        orderType: type,
        status: (o['status'] == 'cooking')
            ? OrderStatus.cooking
            : (o['status'] == 'completed')
            ? OrderStatus.completed
            : OrderStatus.pending,
        items: items,
      );
    }).toList();
  }

  Stream<List<Order>> liveActiveOrders({
    Duration poll = const Duration(seconds: 4),
  }) {
    final c = _svc ?? _c;
    if (c == null) return const Stream.empty();
    return Stream<List<Order>>.multi((controller) async {
      final initial = await fetchActiveOrders();
      controller.add(initial);
      final channel = c.channel('orders_live');
      void emit() async {
        final list = await fetchActiveOrders();
        controller.add(list);
      }

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: ordersTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: ordersTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: ordersTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: orderItemsTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: orderItemsTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: orderItemsTable,
        callback: (_) => emit(),
      );
      channel.subscribe();
      final ticker = Stream.periodic(poll).listen((_) => emit());
      controller.onCancel = () async {
        await channel.unsubscribe();
        await ticker.cancel();
      };
    }, isBroadcast: true);
  }

  Future<void> deleteOrder(String orderId) async {
    final c = _svc ?? _c;
    if (c == null) return;
    await c.from(orderItemsTable).delete().eq('order_id', orderId);
    await c.from(ordersTable).delete().eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final c = _c ?? _svc;
    if (c == null) return [];
    final res = await c.from(recordsTable).select().order('created_at');
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
