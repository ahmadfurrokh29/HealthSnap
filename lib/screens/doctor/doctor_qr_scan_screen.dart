import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_app/services/doctor_session_service.dart';
import 'package:my_app/utils/app_snackbar.dart';

class DoctorQrScanScreen extends StatefulWidget {
  const DoctorQrScanScreen({super.key});

  @override
  State<DoctorQrScanScreen> createState() => _DoctorQrScanScreenState();
}

class _DoctorQrScanScreenState extends State<DoctorQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;

  String _extractPatientId(String raw) {
    final sanitized = raw.trim();
    if (sanitized.contains('-')) {
      return sanitized.split('-').first.trim();
    }
    return sanitized;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) {
      return;
    }

    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final patientId = _extractPatientId(raw);
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      if (!snap.exists) {
        throw Exception('Patient not found for scanned QR');
      }

      final data = snap.data() ?? {};
      final firstName = data['firstName']?.toString().trim() ?? '';
      final lastName = data['lastName']?.toString().trim() ?? '';
      final fallbackName = data['name']?.toString().trim() ?? '';
      final fullName = ('$firstName $lastName').trim().isEmpty
          ? (fallbackName.isEmpty ? 'Unknown Patient' : fallbackName)
          : ('$firstName $lastName').trim();

      await DoctorSessionService().startSession(
        patientId: patientId,
        patientName: fullName,
      );

      if (!mounted) {
        return;
      }

      AppSnackbar.showSuccess(context, 'Session started for $fullName');

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppSnackbar.showError(
          context, e.toString().replaceFirst('Exception: ', ''));
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Patient QR',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _isProcessing
                      ? 'Fetching patient data...'
                      : 'Align QR inside the frame',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
