import 'package:flutter/material.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My QR Code',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'QR Code Page',
          style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }
}
