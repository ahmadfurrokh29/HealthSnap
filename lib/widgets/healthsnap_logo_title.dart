import 'package:flutter/material.dart';

/// Consistent HealthSnap logo + title widget used in every AppBar.
/// Logo size: 22×22, font size: 17, font weight: w700.
class HealthsnapLogoTitle extends StatelessWidget {
  const HealthsnapLogoTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            'Assets/logo3.jpeg',
            width: 26,
            height: 26,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'HealthSnap',
          style: TextStyle(
            color: Color(0xFF3B5BDB),
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ],
    );
  }
}
