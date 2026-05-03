import '../../models/food_item.dart';
import '../models/order.dart';

class AdminData {
  static final AdminData _instance = AdminData._internal();
  factory AdminData() => _instance;
  AdminData._internal();

  final List<FoodItem> items = [];

  final List<Order> orders = [];

  final List<Order> records = [];
}
