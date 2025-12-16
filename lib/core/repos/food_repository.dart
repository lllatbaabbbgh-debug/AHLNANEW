import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';

  // Safe access to Hive box
  Box? get _box {
    try {
      if (Hive.isBoxOpen('food_cache')) {
        return Hive.box('food_cache');
      }
    } catch (_) {}
    return null;
  }

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient;

  Future<List<FoodItem>> fetchByCategory(String category) async {
    final c = _svc ?? _c;

    // 1. Fetch from Cache first (Offline First)
    final box = _box;
    if (box != null) {
      final cachedData = box.get(category);
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = cachedData;
          final items = decoded
              .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (items.isNotEmpty) {
            print('📦 Loaded ${items.length} items from cache for $category');
            _updateCacheInBackground(c, category);
            return items;
          }
        } catch (e) {
          print('⚠️ Error parsing cache for $category: $e');
        }
      }
    } else {
      print('⚠️ Cache box not available, skipping cache read for $category');
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

  Future<List<FoodItem>> fetchByCategoryFresh(String category) async {
    final c = _svc ?? _c;
    if (c == null) {
      return [];
    }
    return await _fetchAndCache(c, category);
  }

  Future<List<FoodItem>> fetchAllFresh() async {
    final svc = _svc;
    final anon = _c;
    List<dynamic>? res;

    // 1. Try Service Client first (Admin privileges)
    if (svc != null) {
      try {
        print('🔄 Fetching all items via Service Client...');
        res = await svc.from(table).select().order('id', ascending: false);
        print('✅ Service Client success: ${res?.length} items');
      } catch (e) {
        print('⚠️ Service client failed to fetch all items: $e');
      }
    } else {
      print('⚠️ Service client is null');
    }

    // 2. Fallback to Anon Client (Public data)
    if (res == null && anon != null) {
      try {
        print('🔄 Fetching all items via Anon Client...');
        res = await anon.from(table).select().order('id', ascending: false);
        print('✅ Anon Client success: ${res?.length} items');
      } catch (e) {
        print('❌ Anon client failed to fetch all items: $e');
      }
    } else if (res == null) {
      print('⚠️ Anon client is null');
    }

    // 3. Process Result & Update Cache
    if (res != null) {
      final box = _box;
      if (box != null) {
        await box.put('__ALL__', res);
      }
      return (res as List)
          .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // 4. Fallback to Cache if Network Failed
    print('⚠️ Network failed, falling back to cache for __ALL__');
    final box = _box;
    if (box != null) {
      final cached = box.get('__ALL__');
      if (cached != null) {
        try {
          final List<dynamic> decoded = cached;
          return decoded
              .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } catch (e) {
          print('❌ Cache parse error: $e');
        }
      }
    } else {
      print('⚠️ Cache box not available, cannot fallback');
    }

    return [];
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
        //.order('sort_order') // Removed: Column missing in DB
        .order('id', ascending: false);

    print('✅ Fetched ${res.length} items for $category');

    final box = _box;
    if (box != null) {
      await box.put(category, res);
    }

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
        //.order('sort_order') // Removed: Column missing in DB
        .order('id', ascending: false)
        .map((rows) {
          // Update cache on stream update too
          final box = _box;
          if (box != null) {
            box.put(category, rows);
          }
          return rows
              .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        })
        .asBroadcastStream();
  }

  Stream<List<FoodItem>> streamWithInitial(String category) {
    return Stream<List<FoodItem>>.multi((controller) async {
      // 1. Emit cached data immediately
      final box = _box;
      if (box != null) {
        final cachedData = box.get(category);
        if (cachedData != null) {
          try {
            final List<dynamic> decoded = cachedData;
            final items = decoded
                .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            controller.add(items);
          } catch (_) {}
        }
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
      int nextOrder = 0;
      // sort_order logic wrapped in try-catch
      try {
        final last = await c
            .from(table)
            .select('sort_order')
            .eq('category', item.category)
            .order('sort_order', ascending: false)
            .limit(1)
            .maybeSingle();
        if (last != null) {
          nextOrder = (last['sort_order'] as int?) ?? 0;
          nextOrder += 1;
        }
      } catch (_) {}

      final payload = item.copyWith(sortOrder: nextOrder).toJson();
      // Remove sort_order if it causes issues.
      payload.remove('sort_order');

      final res = await c.from(table).insert(payload).select().maybeSingle();
      final ok = res != null;
      if (ok) {
        await _fetchAndCache(c, item.category);
      }
      return ok;
    } catch (e) {
      print('Add failed: $e');
      return false;
    }
  }

  Future<bool> update(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      final payload = item.toJson();
      payload.remove('sort_order'); // Safe removal

      final res = await c
          .from(table)
          .update(payload)
          .eq('id', item.id)
          .select();
      final ok = (res.isNotEmpty);
      if (ok) {
        await _fetchAndCache(c, item.category);
      }
      return ok;
    } catch (e) {
      print('Update failed: $e');
      return false;
    }
  }

  Future<bool> updateOrderForCategory(
    String category,
    List<FoodItem> ordered,
  ) async {
    // Save order locally in Hive since DB column is missing
    final box = _box;
    if (box == null) {
      print('⚠️ Cannot save order: Cache box not available');
      return false;
    }
    try {
      final ids = ordered.map((e) => e.id).toList();
      await box.put('order_$category', ids);
      print('📦 Saved local order for $category: $ids');
      return true;
    } catch (e) {
      print('⚠️ Failed to save local order: $e');
      return false;
    }
  }

  List<String> getCategoryOrder(String category) {
    final box = _box;
    if (box == null) return [];
    try {
      final ids = box.get('order_$category');
      if (ids is List) {
        return ids.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> delete(String id) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      final row = await c.from(table).select().eq('id', id).maybeSingle();
      await c.from(table).delete().eq('id', id);

      // If we got here, delete was successful (or no-op if id not found, but we checked row)
      if (row != null) {
        final m = Map<String, dynamic>.from(row);
        final cat = m['category']?.toString() ?? '';
        if (cat.isNotEmpty) {
          await _fetchAndCache(c, cat);
        }
      }
      return true;
    } catch (e) {
      print('Delete failed: $e');
      return false;
    }
  }
}
