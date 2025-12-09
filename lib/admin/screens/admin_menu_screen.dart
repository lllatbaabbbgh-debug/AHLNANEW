import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/supabase_client.dart';
import '../../models/food_item.dart';
import '../../core/repos/food_repository.dart';
import '../../core/repos/category_repository.dart';
import '../../models/category_model.dart';
import 'admin_categories_screen.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late List<FoodItem> items;
  final repo = FoodRepository();
  final catRepo = CategoryRepository();
  
  List<CategoryModel> _allCategories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    items = [];
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await catRepo.getAllCategories();
    // If empty, use defaults (fallback)
    if (cats.isEmpty) {
       _allCategories = [
         const CategoryModel(id: 1, nameEn: 'Lahm Bi Ajeen', nameAr: 'لحم بعجين'),
         const CategoryModel(id: 2, nameEn: 'Pizza', nameAr: 'بيتزا'),
         const CategoryModel(id: 3, nameEn: 'Drinks', nameAr: 'مشروبات'),
       ];
    } else {
      _allCategories = cats;
    }
    
    if (_allCategories.isNotEmpty) {
      selectedCategory = _allCategories.first.nameEn;
    }
    
    await _loadAllItems();
  }

  List<FoodItem> byCat(String c) =>
      items.where((e) => e.category == c).toList();

  Future<void> _loadAllItems() async {
    final all = <FoodItem>[];
    // We only fetch items for leaf categories or all categories?
    // Let's fetch for all to be safe
    for (final c in _allCategories) {
      try {
        final fetched = await repo.fetchByCategory(c.nameEn);
        all.addAll(fetched);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        items = all;
      });
    }
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    String? dialogSelectedCat = selectedCategory;
    bool uploading = false;
    Future<void> pickAndUpload() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final path = f.path;
      if (path == null) return;
      final client = SupabaseManager.serviceClient ?? SupabaseManager.client;
      if (client == null) return;
      final file = File(path);
      final name = f.name.replaceAll(' ', '_');
      final key = 'items/${DateTime.now().millisecondsSinceEpoch}_$name';
      uploading = true;
      try {
        await client.storage.from('food-images').upload(key, file);
        final publicUrl = client.storage.from('food-images').getPublicUrl(key);
        imageCtrl.text = publicUrl;
      } finally {
        uploading = false;
      }
    }

    bool isActive = true;
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              title: const Text('إضافة صنف جديد'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: dialogSelectedCat,
                        items: _allCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.nameEn,
                                child: Text('${c.nameAr} (${c.nameEn})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => dialogSelectedCat = v ?? dialogSelectedCat,
                        decoration: const InputDecoration(labelText: 'القسم'),
                      ),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم'),
                      ),
                      TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'السعر'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                        maxLines: 3,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رابط الصورة',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: uploading ? null : pickAndUpload,
                            child: Text(uploading ? 'جارٍ الرفع...' : 'رفع صورة'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) {
                          setDialogState(() {
                            isActive = v;
                          });
                        },
                        title: const Text('متاح؟'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogSelectedCat == null) return;
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    final newItem = FoodItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      price: price,
                      description: descCtrl.text,
                      imageUrl: imageCtrl.text,
                      category: dialogSelectedCat!,
                      isAvailable: isActive,
                    );
                    final ok = await repo.add(newItem);
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تعذر حفظ الصنف')),
                        );
                      }
                      return;
                    }
                    await _loadAllItems();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editItem(FoodItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final descCtrl = TextEditingController(text: item.description);
    final imageCtrl = TextEditingController(text: item.imageUrl);
    bool uploading = false;
    Future<void> pickAndUpload() async {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final path = f.path;
      if (path == null) return;
      final client = SupabaseManager.serviceClient ?? SupabaseManager.client;
      if (client == null) return;
      final file = File(path);
      final name = f.name.replaceAll(' ', '_');
      final key = 'items/${DateTime.now().millisecondsSinceEpoch}_$name';
      uploading = true;
      try {
        await client.storage.from('food-images').upload(key, file);
        final publicUrl = client.storage.from('food-images').getPublicUrl(key);
        imageCtrl.text = publicUrl;
      } finally {
        uploading = false;
      }
    }

    bool isActive = item.isAvailable;
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              title: const Text('تعديل الصنف'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'الاسم'),
                      ),
                      TextField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'السعر'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'الوصف'),
                        maxLines: 3,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'رابط الصورة',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: uploading ? null : pickAndUpload,
                            child: Text(uploading ? 'جارٍ الرفع...' : 'رفع صورة'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (v) {
                          setDialogState(() {
                            isActive = v;
                          });
                        },
                        title: const Text('متاح؟'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = item.copyWith(
                      name: nameCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? item.price,
                      description: descCtrl.text,
                      imageUrl: imageCtrl.text,
                      isAvailable: isActive,
                    );
                    setState(() {
                      final idx = items.indexWhere((e) => e.id == item.id);
                      items[idx] = updated;
                    });
                    final ok = await repo.update(updated);
                    if (!ok) {
                      setState(() {
                        final idx = items.indexWhere((e) => e.id == item.id);
                        items[idx] = item;
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر حفظ التغيير')),
                      );
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await _loadAllItems();
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = selectedCategory == null ? <FoodItem>[] : byCat(selectedCategory!);
    
    final parents = _allCategories.where((c) => c.parentId == null).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: ListView(
              children: parents.map((p) {
                final children = _allCategories.where((c) => c.parentId == p.id).toList();
                if (children.isEmpty) {
                   return ListTile(
                    title: Text(p.nameAr),
                    selected: selectedCategory == p.nameEn,
                    onTap: () async {
                      setState(() => selectedCategory = p.nameEn);
                    },
                  );
                }
                return ExpansionTile(
                  title: Text(p.nameAr),
                  initiallyExpanded: true,
                  children: [
                     ListTile(
                      title: Text('الكل في ${p.nameAr}'),
                      selected: selectedCategory == p.nameEn,
                      onTap: () => setState(() => selectedCategory = p.nameEn),
                    ),
                    ...children.map((child) => ListTile(
                      title: Text(child.nameAr),
                      contentPadding: const EdgeInsets.only(right: 32),
                      selected: selectedCategory == child.nameEn,
                      onTap: () => setState(() => selectedCategory = child.nameEn),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _addItem,
                        child: const Text('إضافة صنف'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _loadData,
                        child: const Text('مزامنة'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.category),
                        label: const Text('إدارة الأقسام'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                           await Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                           );
                           _loadData();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final it = list[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            it.imageUrl,
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
                        title: Text(it.name),
                        subtitle: Text(
                          '${it.price % 1 == 0 ? it.price.toInt() : it.price} IQD',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: it.isAvailable,
                              onChanged: (v) async {
                                print('🔄 Toggling availability for ${it.name}: $v');
                                final updated = it.copyWith(isAvailable: v);
                                print('📦 Updated item data: ${updated.toJson()}');
                                setState(() {
                                  final idx = items.indexWhere(
                                    (e) => e.id == it.id,
                                  );
                                  items[idx] = updated;
                                });
                                final ok = await repo.update(updated);
                                if (!ok) {
                                  print('❌ Database update failed or no rows modified');
                                  // Revert on error
                                  setState(() {
                                    final idx = items.indexWhere(
                                      (e) => e.id == it.id,
                                    );
                                    items[idx] = it;
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تعذر حفظ التغيير')), 
                                  );
                                } else {
                                  print('✅ Database update completed');
                                  await _loadAllItems();
                                }
                              },
                            ),
                            IconButton(
                              onPressed: () => _editItem(it),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    final cs2 = Theme.of(context).colorScheme;
                                    return AlertDialog(
                                      backgroundColor: cs2.surface,
                                      title: const Text('حذف الصنف'),
                                      content: const Text(
                                        'هل تريد حذف هذا الصنف بشكل نهائي؟',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('حذف'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (ok == true) {
                                  await repo.delete(it.id);
                                  setState(() {
                                    items.removeWhere((e) => e.id == it.id);
                                  });
                                }
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}
