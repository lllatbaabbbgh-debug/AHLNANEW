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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // -----------------------------------------------------------
  // المنطق كما هو (بدون تغيير)
  // -----------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // متغيرات الأنميشن
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
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
      Storage.saveProfile(
        name: profile.name,
        phone: profile.phone,
        address: profile.address,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootScaffold()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // سحب الألوان من ثيم التطبيق الأصلي
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // جعل الخلفية رمادي فاتح جداً لتبرز البطاقة البيضاء
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- الجزء العلوي (الهيدر) ---
            Stack(
              children: [
                ClipPath(
                  clipper: CustomHeaderClipper(),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // استخدام لون التطبيق الأصلي مع تدرج بسيط
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_pin_circle_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "أهلنا داقوق",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black26, blurRadius: 10),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "يرجى تسجيل بياناتك",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- بطاقة الإدخال ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, // البطاقة بيضاء دائماً
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildFixedColorField(
                            controller: _nameController,
                            label: 'اسمك الكريم',
                            icon: Icons.person,
                            themeColor: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          _buildFixedColorField(
                            controller: _phoneController,
                            label: 'رقم الهاتف (0770...)',
                            icon: Icons.phone_android,
                            themeColor: primaryColor,
                            isPhone: true,
                          ),
                          const SizedBox(height: 16),
                          _buildFixedColorField(
                            controller: _addressController,
                            label: 'العنوان الكامل',
                            icon: Icons.location_on,
                            themeColor: primaryColor,
                            isMultiLine: true,
                          ),
                          const SizedBox(height: 30),

                          // زر الحفظ
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    primaryColor, // لون الزر نفس لون التطبيق
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: primaryColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'حفظ ومتابعة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // هذه الدالة تم تعديلها لإصلاح مشكلة الألوان
  Widget _buildFixedColorField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color themeColor,
    bool isPhone = false,
    bool isMultiLine = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: isMultiLine ? 3 : 1,
      // ⚠️ هنا التعديل المهم: أجبرنا النص يكون أسود لأن الخلفية بيضاء
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        // لون الليبل (العنوان) رمادي غامق ليظهر بوضوح
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black26),
        prefixIcon: Icon(
          icon,
          color: themeColor,
        ), // لون الايقونة نفس لون التطبيق
        filled: true,
        fillColor: const Color(0xFFF9F9F9), // لون خلفية الحقل رمادي فاتح جداً
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeColor, width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
    );
  }
}

// كلاس الرسم (نفسه)
class CustomHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
