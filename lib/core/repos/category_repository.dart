import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_model.dart';
import '../supabase_client.dart';

class CategoryRepository {
  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient ?? _c;

  Future<List<CategoryModel>> getAllCategories() async {
    final c = _c;
    if (c == null) return [];
    try {
      final response = await c
          .from('categories')
          .select()
          .order('id', ascending: true);
      
      return (response as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Stream<List<CategoryModel>> streamCategories() {
    final c = _c;
    if (c == null) return Stream.value([]);
    return c
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .map((data) => data.map((e) => CategoryModel.fromJson(e)).toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    final svc = _svc;
    if (svc == null) return;
    await svc.from('categories').insert(category.toJson());
  }

  Future<void> updateCategory(CategoryModel category) async {
    final svc = _svc;
    if (svc == null) return;
    await svc
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  Future<void> deleteCategory(int id) async {
    final svc = _svc;
    if (svc == null) return;
    await svc.from('categories').delete().eq('id', id);
  }
}
