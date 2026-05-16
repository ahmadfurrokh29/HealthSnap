import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/screens/doctor/doctor_patient_history_screen.dart';
import 'package:my_app/screens/doctor/doctor_patient_reports_screen.dart';
import 'package:my_app/screens/doctor/widgets/doctor_app_bar.dart';
import 'package:my_app/services/doctor_session_service.dart';
import 'package:my_app/utils/app_snackbar.dart';

class DoctorPatientsScreen extends StatelessWidget {
  const DoctorPatientsScreen({super.key});

  static String _safe(dynamic val) {
    if (val == null || val.toString().trim().isEmpty) return '---';
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const DoctorAppBar(showLogout: false),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: DoctorSessionService().activeSessionStream(),
        builder: (context, sessionSnapshot) {
          final sessionData = sessionSnapshot.data?.data();
          final patientId = sessionData?['patientId']?.toString();
          final sessionPatientName =
              sessionData?['patientName']?.toString() ?? 'Patient';

          if (patientId == null || patientId.isEmpty) {
            return _noPatientState();
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(patientId)
                .snapshots(),
            builder: (context, userSnap) {
              final u = userSnap.data?.data() ?? {};
              final rawFull = ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}')
                  .trim();
              final fullName = rawFull.isEmpty ? sessionPatientName : rawFull;

              // Stack layout:
              //  Layer 1 = top static cards
              //  Layer 2 = draggable/scrollable patient info sheet
              // The sheet always sits above cards and can be dragged to top.
              return Stack(
                children: [
                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          children: [
                            _navCard(
                              context,
                              iconData: Icons.history,
                              iconBg: const Color(0xFFE6F4EA),
                              iconColor: const Color(0xFF2E7D32),
                              title: 'View Medical History',
                              subtitle:
                                  'Access complete patient journey and past diagnoses',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorPatientHistoryScreen(
                                    patientId: patientId,
                                    patientName: fullName,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _navCard(
                              context,
                              iconData: Icons.description_outlined,
                              iconBg: const Color(0xFFE6F4EA),
                              iconColor: const Color(0xFF2E7D32),
                              title: 'View Medical Reports',
                              subtitle:
                                  'Review lab results, imaging, and specialist notes',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorPatientReportsScreen(
                                    patientId: patientId,
                                    patientName: fullName,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: 0.42,
                    minChildSize: 0.42,
                    maxChildSize: 1.0,
                    expand: true,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionHeader('Basic Info'),
                                    const SizedBox(height: 12),
                                    _infoCard([
                                      _infoRow('FULL NAME', fullName),
                                      _divider(),
                                      _infoRow('DATE OF BIRTH', _safe(u['dob'])),
                                      _divider(),
                                      _infoRow('AGE', _safe(u['age'])),
                                      _divider(),
                                      _infoRow(
                                        'BLOOD GROUP',
                                        _safe(u['bloodGroup']),
                                      ),
                                    ]),
                                    const SizedBox(height: 22),
                                    _sectionHeader('Health Information'),
                                    const SizedBox(height: 12),
                                    _infoCard([
                                      _infoRow('HEIGHT', _safe(u['height'])),
                                      _divider(),
                                      _infoRow('WEIGHT', _safe(u['weight'])),
                                      _divider(),
                                      _infoRow('ALLERGIES', _safe(u['allergies'])),
                                    ]),
                                    const SizedBox(height: 22),
                                    _sectionHeader('Contact Information'),
                                    const SizedBox(height: 12),
                                    _infoCard([
                                      _infoRowWithCopy(
                                        context,
                                        'PHONE NUMBER',
                                        _safe(u['phone']),
                                      ),
                                      _divider(),
                                      _infoRowWithCopy(
                                        context,
                                        'EMERGENCY PHONE',
                                        _safe(u['emergencyPhone']),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────

  Widget _navCard(
    BuildContext context, {
    required IconData iconData,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(iconData, color: iconColor, size: 34),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 40 / 2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 30 / 2,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF3B5BDB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithCopy(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    if (value == '---') {
                      return;
                    }
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) {
                      return;
                    }
                    AppSnackbar.showInfo(
                      context,
                      '$label copied',
                      duration: const Duration(milliseconds: 900),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    indent: 18,
    endIndent: 18,
    color: Color(0xFFF3F4F6),
  );

  Widget _noPatientState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
            color: Color(0xFFD1D5DB),
          ),
          SizedBox(height: 16),
          Text(
            'No active patient',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Scan a patient QR to begin a session',
            style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }
}
