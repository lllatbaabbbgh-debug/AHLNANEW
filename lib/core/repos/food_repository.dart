import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';
  final Box _box = Hive.box('food_cache');

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient;

  Future<List<FoodItem>> fetchByCategory(String category) async {
    final c = _svc ?? _c;

    // 1. Fetch from Cache first (Offline First)
    final cachedData = _box.get(category);
    if (cachedData != null) {
      try {
        final List<dynamic> decoded = cachedData;
        final items = decoded
            .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (items.isNotEmpty) {
          print('📦 Loaded ${items.length} items from cache for $category');
          // We return cached items, but we also want to trigger an update in background if possible
          // However, as a Future, we return what we have.
          // For "Live" updates, stream logic handles it better, but for single fetch:
          _updateCacheInBackground(c, category);
          return items;
        }
      } catch (e) {
        print('⚠️ Error parsing cache for $category: $e');
      }
    }

    if (c == null) {
      print('❌ No Supabase client available');
      return [];
    }

    // 2. If no cache or cache error, fetch from network
    try {
      return await _fetchAndCache(c, category);
    } catch (e) {
      print('❌ Error fetching items for $category: $e');
      return [];
    }
  }

  Future<void> _updateCacheInBackground(
    SupabaseClient? c,
    String category,
  ) async {
    if (c == null) return;
    try {
      await _fetchAndCache(c, category);
      print('🔄 Background cache update completed for $category');
    } catch (e) {
      print('⚠️ Background cache update failed for $category: $e');
    }
  }

  Future<List<FoodItem>> _fetchAndCache(
    SupabaseClient c,
    String category,
  ) async {
    print('🔍 Fetching items for category from network: $category');
    final res = await c
        .from(table)
        .select()
        .eq('category', category)
        .order('name');

    print('✅ Fetched ${res.length} items for $category');

    await _box.put(category, res);

    return (res as List)
        .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Stream<List<FoodItem>> streamByCategory(String category) {
    final c = _svc ?? _c;
    if (c == null) return const Stream.empty();
    return c
        .from(table)
        .stream(primaryKey: ['id'])
        .eq('category', category)
        .order('name')
        .map((rows) {
          // Update cache on stream update too
          _box.put(category, rows);
          return rows
              .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        })
        .asBroadcastStream();
  }

  Stream<List<FoodItem>> streamWithInitial(String category) {
    return Stream<List<FoodItem>>.multi((controller) async {
      // 1. Emit cached data immediately
      final cachedData = _box.get(category);
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = cachedData;
          final items = decoded
              .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          controller.add(items);
        } catch (_) {}
      }

      // 2. Fetch fresh data and emit
      try {
        final initial = await fetchByCategory(category);
        controller.add(initial);
      } catch (_) {
        // If network fails, we already emitted cache.
      }

      // 3. Listen to real-time updates if online
      final sub = streamByCategory(
        category,
      ).listen(controller.add, onError: controller.addError);
      controller.onCancel = () => sub.cancel();
    }, isBroadcast: true);
  }

  Stream<List<FoodItem>> liveByCategory(String category) {
    return streamWithInitial(category);
  }

  Future<bool> add(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      final res = await c
          .from(table)
          .insert(item.toJson())
          .select()
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
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
