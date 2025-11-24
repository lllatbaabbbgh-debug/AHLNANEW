import '../../models/food_item.dart';
import '../../core/sample_data.dart';
import '../models/order.dart';

class AdminData {
  static final AdminData _instance = AdminData._internal();
  factory AdminData() => _instance;
  AdminData._internal();

  final List<FoodItem> items = List.of(sampleFoodItems);

  final List<Order> orders = [
    Order(
      id: 'ORD-1001',
      customerName: 'علي محمد',
      phone: '07701234567',
      address: 'داقوق، حي المعلمين',
      items: [OrderItem(item: sampleFoodItems[0], quantity: 3), OrderItem(item: sampleFoodItems[3], quantity: 1)],
    ),
    Order(
      id: 'ORD-1002',
      customerName: 'حسين أحمد',
      phone: '07819887766',
      address: 'كركوك، شارع بغداد',
      items: [OrderItem(item: sampleFoodItems[2], quantity: 2)],
    ),
  ];

  final List<Order> records = [];
}

