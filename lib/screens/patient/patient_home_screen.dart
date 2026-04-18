import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientHomeScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  final VoidCallback? onQrTap;

  const PatientHomeScreen({super.key, this.onSwitchTab, this.onQrTap});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  String _userName = 'User';
  int _totalRecords = 0;
  int _totalReports = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchCounts();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _userName = doc.data()?['firstName'] ??
            doc.data()?['name']?.toString().split(' ').first ??
            doc.data()?['email'] ??
            'User';
      });
    }
  }

  Future<void> _fetchCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final historySnap = await FirebaseFirestore.instance
        .collection('medical_history')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    final reportsSnap = await FirebaseFirestore.instance
        .collection('medical_reports')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    if (mounted) {
      setState(() {
        _totalRecords = historySnap.count ?? 0;
        _totalReports = reportsSnap.count ?? 0;
      });
    }
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
          onPressed: () {},
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Greeting
            Text(
              'Hello, $_userName',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your health metrics are looking stable today.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                _buildStatCard(
                  'TOTAL RECORDS',
                  _totalRecords,
                  const Color(0xFF3B5BDB),
                  const Color(0xFF3B5BDB),
                  const Color(0xFFEEF2FF),
                ),
                const SizedBox(width: 14),
                _buildStatCard(
                  'TOTAL REPORTS',
                  _totalReports,
                  const Color(0xFF1B8A4E),
                  const Color(0xFF1B8A4E),
                  const Color(0xFFF0FAF4),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Scan Reports & History big blue card
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/scan');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B5BDB), Color(0xFF2B4ACB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan Reports & History',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Digitize your medical paper records instantly\nwith AI',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // View Medical History + View Lab Reports
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.quiz_outlined,
                    iconBgColor: const Color(0xFFE8EEFF),
                    iconColor: const Color(0xFF3B5BDB),
                    title: 'View Medical\nHistory',
                    onTap: () {
                      widget.onSwitchTab?.call(1);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.find_in_page_outlined,
                    iconBgColor: const Color(0xFFE6F9F0),
                    iconColor: const Color(0xFF2ECC71),
                    title: 'View Lab\nReports',
                    onTap: () {
                      widget.onSwitchTab?.call(2);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // My QR Code
            GestureDetector(
              onTap: () {
                widget.onQrTap?.call();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Color(0xFF3B5BDB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My QR Code',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share your profile with doctors',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF9CA3AF),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Wellness Tip
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
                    'WELLNESS TIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2ECC71),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Stay Hydrated',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Maintaining hydration levels helps your metabolic lab results stay accurate.',
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

  Widget _buildStatCard(String label, int value, Color labelColor, Color valueColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Icon(
              Icons.arrow_forward,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
