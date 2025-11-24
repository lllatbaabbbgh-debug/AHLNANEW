import 'package:flutter/material.dart';

class ProfileController extends ChangeNotifier {
  String name = '';
  String phone = '';
  String address = '';

  void set({String? name, String? phone, String? address}) {
    if (name != null) this.name = name;
    if (phone != null) this.phone = phone;
    if (address != null) this.address = address;
    notifyListeners();
  }
}

class ProfileProvider extends InheritedNotifier<ProfileController> {
  final ProfileController controller;
  const ProfileProvider({super.key, required this.controller, required super.child})
      : super(notifier: controller);

  static ProfileController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ProfileProvider>();
    assert(provider != null, 'ProfileProvider not found');
    return provider!.controller;
  }

  @override
  bool updateShouldNotify(covariant InheritedNotifier<ProfileController> oldWidget) => true;
}

