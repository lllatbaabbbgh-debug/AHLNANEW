import 'package:flutter/material.dart';
import '../core/admin_data.dart';
import '../../core/repos/order_repository.dart';

class AdminRecordsScreen extends StatefulWidget {
  const AdminRecordsScreen({super.key});

  @override
  State<AdminRecordsScreen> createState() => _AdminRecordsScreenState();
}

class _AdminRecordsScreenState extends State<AdminRecordsScreen> {
  final data = AdminData();
  final repo = OrderRepository();
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await repo.fetchRecords();
    setState(() => records = list);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final o = records[index];
          return Container(
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(o['id']?.toString() ?? ''),
              subtitle: Text('المجموع: ${(o['total_price'] as num?)?.toDouble().toString() ?? '0'} IQD'),
            ),
          );
        },
      ),
    );
  }
}
