import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/supabase_client.dart';
import '../../models/food_item.dart';
import '../../core/repos/food_repository.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  late List<FoodItem> items;
  final repo = FoodRepository();
  final List<String> categories = const ['Lahm Bi Ajeen', 'Pizza', 'Drinks'];
  final Map<String, String> categoryAr = const {
    'Lahm Bi Ajeen': 'لحم بعجين',
    'Pizza': 'بيتزا',
    'Drinks': 'مشروبات',
  };
  String selected = 'Lahm Bi Ajeen';

  @override
  void initState() {
    super.initState();
    items = [];
    _loadAll();
  }

  List<FoodItem> byCat(String c) =>
      items.where((e) => e.category == c).toList();

  Future<void> _loadCategory() async {
    final fetched = await repo.fetchByCategory(selected);
    setState(() {
      items.removeWhere((e) => e.category == selected);
      items.addAll(fetched);
    });
  }

  Future<void> _loadAll() async {
    final all = <FoodItem>[];
    for (final c in categories) {
      final fetched = await repo.fetchByCategory(c);
      all.addAll(fetched);
    }
    setState(() {
      items = all;
    });
  }

  void _addItem() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
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
                        initialValue: selected,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(categoryAr[c]!),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => selected = v ?? selected,
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
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    final newItem = FoodItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      price: price,
                      description: descCtrl.text,
                      imageUrl: imageCtrl.text,
                      category: selected,
                      isAvailable: isActive,
                    );
                    setState(() => items.add(newItem));
                    await repo.add(newItem);
                    await _loadCategory();
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
                    await _loadCategory();
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
    final list = byCat(selected);
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: ListView(
            children: categories.map((c) {
              final sel = c == selected;
              return ListTile(
                title: Text(categoryAr[c]!),
                selected: sel,
                onTap: () async {
                  setState(() => selected = c);
                  await _loadCategory();
                },
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
                      onPressed: _loadCategory,
                      child: const Text('مزامنة من القاعدة'),
                    ),
                    const SizedBox(width: 12),
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
                                  await _loadCategory();
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
    );
  }
}
