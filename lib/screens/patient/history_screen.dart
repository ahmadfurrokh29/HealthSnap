import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/patient/history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const HistoryScreen({super.key, this.onBack});

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined,
                color: const Color(0xFF3B5BDB), size: 20),
            const SizedBox(width: 6),
            const Text(
              'HealthSnap',
              style: TextStyle(
                color: Color(0xFF3B5BDB),
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medical_history')
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
                  'CLINICAL RECORDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B5BDB),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Medical History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your clinical journey and past consultations.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
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
                        Icon(Icons.history_edu_outlined, size: 48, color: Color(0xFFD1D5DB)),
                        SizedBox(height: 12),
                        Text(
                          'No medical history yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scan a doctor visit record to get started',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ...docs.map((doc) {
                  final record = doc.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildHistoryCard(context, record, doc.id),
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

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this medical history record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('medical_history').doc(docId).delete();
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53E3E), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> record, String docId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(record: record),
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
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF3B5BDB)),
                const SizedBox(width: 6),
                Text(
                  _safe(record['date']),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3B5BDB)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(context, docId),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFE53E3E), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _safe(record['diagnosis']),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _safe(record['clinicName']),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRACTITIONER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
                    Text(_safe(record['doctorName']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  ],
                ),
                const SizedBox(width: 24),
                const Icon(Icons.local_pharmacy_outlined, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MEDICINES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
                    Text('${record['medicineCount'] ?? 0} Prescribed', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3B5BDB))),
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
