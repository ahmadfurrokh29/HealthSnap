import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/services/cloudinary_service.dart';
import 'package:my_app/services/gemini_service.dart';
import 'package:my_app/utils/app_snackbar.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';

class ScanScreen extends StatelessWidget {
  ScanScreen({super.key});

  final ImagePicker _picker = ImagePicker();

  Future<void> _processImage(BuildContext outerContext, XFile image, String scanType) async {
    // Show loading dialog
    showDialog(
      context: outerContext,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          margin: EdgeInsets.symmetric(horizontal: 60),
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF3B5BDB)),
                SizedBox(height: 18),
                Text(
                  'Analyzing document...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  'AI is extracting your medical data',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final file = File(image.path);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      if (scanType == 'Scan Medical History') {
        late Map<String, dynamic> data;
        try {
          data = await GeminiService.extractMedicalHistory(file);
        } catch (_) {
          throw Exception('AI service is busy. Please try again.');
        }
        // Validate: must have at least one meaningful field
        final hasDiagnosis = (data['diagnosis']?.toString() ?? '').isNotEmpty;
        final hasDoctor = (data['doctorName']?.toString() ?? '').isNotEmpty;
        final hasClinic = (data['clinicName']?.toString() ?? '').isNotEmpty;
        if (!hasDiagnosis && !hasDoctor && !hasClinic) {
          throw Exception('No medical record found. Please scan a valid prescription or medical document.');
        }
        // Upload image to Cloudinary and save URL
        String imageUrl = '';
        try {
          imageUrl = await CloudinaryService.uploadImage(file);
        } catch (e) {
          debugPrint('==== CLOUDINARY UPLOAD ERROR (history): $e ====');
        }
        data['userId'] = uid;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['medicineCount'] = (data['medicines'] as List?)?.length ?? 0;
        data['imageUrl'] = imageUrl;
        await FirebaseFirestore.instance.collection('medical_history').add(data);
      } else {
        late Map<String, dynamic> data;
        try {
          data = await GeminiService.extractMedicalReport(file);
        } catch (_) {
          throw Exception('AI service is busy. Please try again.');
        }
        // Validate: must have testName or at least one parameter
        final hasTestName = (data['testName']?.toString() ?? '').isNotEmpty;
        final hasParams = (data['parameters'] as List?)?.isNotEmpty == true;
        if (!hasTestName && !hasParams) {
          throw Exception('No medical report found. Please scan a valid lab report or medical document.');
        }
        // Upload image to Cloudinary and save URL
        String imageUrl = '';
        try {
          imageUrl = await CloudinaryService.uploadImage(file);
        } catch (e) {
          // Upload failure is non-fatal — report is still saved without image
          debugPrint('==== CLOUDINARY UPLOAD ERROR: $e ====');
        }
        data['userId'] = uid;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['parametersCount'] = (data['parameters'] as List?)?.length ?? 0;
        data['imageUrl'] = imageUrl;
        await FirebaseFirestore.instance.collection('medical_reports').add(data);
      }

      if (outerContext.mounted) {
        Navigator.of(outerContext, rootNavigator: true).pop(); // close loading dialog
        AppSnackbar.showSuccess(
          outerContext,
          scanType == 'Scan Medical History'
              ? 'Medical history saved successfully!'
              : 'Medical report saved successfully!',
        );
      }
    } catch (e) {
      if (outerContext.mounted) {
        Navigator.of(outerContext, rootNavigator: true).pop(); // close loading dialog
        AppSnackbar.showError(
          outerContext,
          e.toString().replaceFirst('Exception: ', ''),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<void> _showSourcePicker(BuildContext context, String scanType) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  scanType,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose image source',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceOption(
                        context: ctx,
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        color: const Color(0xFF3B5BDB),
                        bgColor: const Color(0xFFEEF2FF),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final image = await _picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (image != null && context.mounted) {
                            _processImage(context, image, scanType);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSourceOption(
                        context: ctx,
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        color: const Color(0xFF2ECC71),
                        bgColor: const Color(0xFFF0FAF4),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null && context.mounted) {
                            _processImage(context, image, scanType);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        title: const HealthsnapLogoTitle(),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Scan Documents',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Digitize your medical paper records instantly with AI-powered scanning.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            // Scan Medical Report card
            GestureDetector(
              onTap: () => _showSourcePicker(context, 'Scan Medical Report'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF3B5BDB).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B5BDB).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF3B5BDB),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Medical Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan lab reports, prescriptions, and test results',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF3B5BDB),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Scan Medical History card
            GestureDetector(
              onTap: () => _showSourcePicker(context, 'Scan Medical History'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_edu_outlined,
                        color: Color(0xFF2ECC71),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Medical History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan doctor visits, diagnosis records, and treatment history',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF2ECC71),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Static tip card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD1F2E0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCANNING TIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2ECC71),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Better Scans, Better Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Place documents on a flat surface with good lighting for the best OCR accuracy.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
