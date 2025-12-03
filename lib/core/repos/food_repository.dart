import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient;

  Future<List<FoodItem>> fetchByCategory(String category) async {
    final c = _svc ?? _c;
    if (c == null) {
      print('❌ No Supabase client available');
      return [];
    }
    try {
      print('🔍 Fetching items for category: $category');
      final res = await c
          .from(table)
          .select()
          .eq('category', category)
          .order('name');
      print('✅ Fetched ${res.length} items for $category');
      if (res.isNotEmpty) {
        print('🔑 First item keys: ${(res.first as Map).keys.toList()}');
        print('📄 First item data: ${res.first}');
      }
      return (res as List)
          .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('❌ Error fetching items for $category: $e');
      return [];
    }
  }

  Stream<List<FoodItem>> streamByCategory(String category) {
    final c = _svc ?? _c;
    if (c == null) return const Stream.empty();
    return c
        .from(table)
        .stream(primaryKey: ['id'])
        .eq('category', category)
        .order('name')
        .map(
          (rows) => rows
              .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        )
        .asBroadcastStream();
  }

  Stream<List<FoodItem>> streamWithInitial(String category) {
    return Stream<List<FoodItem>>.multi((controller) async {
      final initial = await fetchByCategory(category);
      controller.add(initial);
      final sub = streamByCategory(
        category,
      ).listen(controller.add, onError: controller.addError);
      controller.onCancel = () => sub.cancel();
    }, isBroadcast: true);
  }

  Stream<List<FoodItem>> liveByCategory(String category) {
    return streamWithInitial(category);
  }

  Future<void> add(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return;
    await c.from(table).insert(item.toJson());
  }

  Future<bool> update(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    print('📝 Updating item: ${item.id}, isAvailable: ${item.isAvailable}');
    print('📊 Data being sent: ${item.toJson()}');
    try {
      final res = await c
          .from(table)
          .update(item.toJson())
          .eq('id', item.id)
          .select();
      final ok = (res.isNotEmpty);
      print(
        ok
            ? '✅ Update successful for item: ${item.id}'
            : '⚠️ Update returned empty, item not modified: ${item.id}',
      );
      return ok;
    } catch (e) {
      print('❌ Update failed for item: ${item.id}, error: $e');
      return false;
    }
  }

  Future<void> delete(String id) async {
    final c = _svc ?? _c;
    if (c == null) return;
    await c.from(table).delete().eq('id', id);
  }
}
