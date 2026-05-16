import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/patient/report_detail_screen.dart';
import 'package:my_app/services/cloudinary_service.dart';

class ReportsScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ReportsScreen({super.key, this.onBack});

  String _safe(dynamic val) => (val == null || val.toString().isEmpty) ? '---' : val.toString();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            }
          },
        ),
        title: const HealthsnapLogoTitle(),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medical_reports')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Medical Reports',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Secure access to your laboratory\nresults and diagnostic history.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (docs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.description_outlined, size: 48, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text(
                          'No medical reports yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scan a lab report to get started',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ...docs.map((doc) {
                  final report = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildReportCard(context, report, doc.id),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Report', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this medical report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (imageUrl.isNotEmpty) {
                try { await CloudinaryService.deleteImage(imageUrl); } catch (_) {}
              }
              await FirebaseFirestore.instance.collection('medical_reports').doc(docId).delete();
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report, String docId) {
    final params = (report['parameters'] as List<dynamic>?) ?? [];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(report: report),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _safe(report['testName']),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context, docId, report['imageUrl']?.toString() ?? ''),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFE53E3E), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  _safe(report['labName']),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(_safe(report['testDate']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PARAMETERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text('${params.length.toString().padLeft(2, '0')} Analyzed', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3B5BDB))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
