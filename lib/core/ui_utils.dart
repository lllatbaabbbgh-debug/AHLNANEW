import 'package:flutter/material.dart';

void showModernSnackBar(BuildContext context, String message, {Color? color, IconData? icon}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
      backgroundColor: color ?? const Color(0xFF23AA49), // Primary Green
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      margin: EdgeInsets.only(
        bottom: 50,
        left: MediaQuery.of(context).size.width > 600
            ? MediaQuery.of(context).size.width * 0.3
            : 40,
        right: MediaQuery.of(context).size.width > 600
            ? MediaQuery.of(context).size.width * 0.3
            : 40,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      elevation: 6,
      duration: const Duration(seconds: 1),
    ),
  );
}
