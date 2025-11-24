import 'package:flutter/material.dart';
import '../core/profile.dart';
import '../core/repos/profile_repository.dart';
import '../main.dart';
import '../core/storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final profile = ProfileProvider.of(context);
      profile.set(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      final repo = ProfileRepository();
      repo.upsert(
        phone: profile.phone,
        name: profile.name,
        address: profile.address,
        user: profile.phone,
      );
      Storage.saveProfile(name: profile.name, phone: profile.phone, address: profile.address);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RootScaffold()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل البيانات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'اسمك الكريم',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'بلا زحمة اكتب اسمك';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'رقم الهاتف (مثال: 0770...)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب رقم الهاتف';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'العنوان الكامل (المنطقة، اقرب نقطة دالة)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'العنوان ضروري حتى يوصلك الطلب';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _submit, child: const Text('حفظ')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
