import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/utils/app_snackbar.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';

class DoctorPastSessionsScreen extends StatelessWidget {
  const DoctorPastSessionsScreen({super.key});

  String _formatDuration(Timestamp? start, Timestamp? end) {
    if (start == null || end == null) return '--';
    final diff = end.toDate().difference(start.toDate());
    final mins = diff.inMinutes;
    final secs = diff.inSeconds % 60;
    if (mins >= 60) {
      return '${diff.inHours}h ${mins % 60}m';
    }
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  Future<void> _deleteAll(BuildContext context, String doctorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete All Sessions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete all past session records? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete All',
              style: TextStyle(
                color: Color(0xFFE53E3E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final snaps = await FirebaseFirestore.instance
        .collection('doctor_sessions')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snaps.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) {
      return const Scaffold(
        body: Center(child: Text('Doctor not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const HealthsnapLogoTitle(),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Color(0xFFE53E3E),
            ),
            tooltip: 'Delete all sessions',
            onPressed: () => _deleteAll(context, doctorId),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('doctor_sessions')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load sessions',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: Color(0xFFD1D5DB),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No past sessions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Completed sessions will appear here',
                    style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
                  ),
                ],
              ),
            );
          }

          // Sort by endedAt descending
          final sorted = [...docs];
          sorted.sort((a, b) {
            final aEnd = a.data()['endedAt'];
            final bEnd = b.data()['endedAt'];
            if (aEnd is! Timestamp || bEnd is! Timestamp) return 0;
            return bEnd.compareTo(aEnd);
          });

          // Group by local date (yyyy-MM-dd)
          final Map<
            String,
            List<QueryDocumentSnapshot<Map<String, dynamic>>>
          > grouped = {};
          for (final doc in sorted) {
            final endedAt = doc.data()['endedAt'];
            final dateKey = endedAt is Timestamp
                ? DateFormat('yyyy-MM-dd').format(endedAt.toDate().toLocal())
                : 'unknown';
            grouped.putIfAbsent(dateKey, () => []).add(doc);
          }

          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: sortedKeys.length,
            itemBuilder: (context, idx) {
              final dateKey = sortedKeys[idx];
              final sessions = grouped[dateKey]!;
              final displayDate = dateKey == 'unknown'
                  ? 'Unknown Date'
                  : DateFormat(
                      'EEEE, MMMM d, y',
                    ).format(DateTime.parse(dateKey));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (idx != 0) const SizedBox(height: 20),
                  // ── Date header ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${sessions.length} patient${sessions.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B5BDB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Session cards ─────────────────────────────────
                  ...sessions.map(
                    (doc) => _SessionCard(
                      doc: doc,
                      formatDuration: _formatDuration,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Session card ────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String Function(Timestamp?, Timestamp?) formatDuration;

  const _SessionCard({required this.doc, required this.formatDuration});

  static String _safe(dynamic val) {
    if (val == null || val.toString().trim().isEmpty) return '---';
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final patientId = data['patientId']?.toString() ?? '';
    final patientName = data['patientName']?.toString() ?? 'Unknown Patient';
    final startedAt = data['startedAt'] as Timestamp?;
    final endedAt = data['endedAt'] as Timestamp?;
    final duration = formatDuration(startedAt, endedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
        child: patientId.isEmpty
            ? _CardContent(
                name: patientName,
                duration: duration,
                phone: '---',
                emergencyPhone: '---',
              )
            : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(patientId)
                    .get(),
                builder: (context, snap) {
                  final u = snap.data?.data() ?? {};
                  final rawFull =
                      ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim();
                  return _CardContent(
                    name: rawFull.isEmpty ? patientName : rawFull,
                    duration: duration,
                    phone: _safe(u['phone']),
                    emergencyPhone: _safe(u['emergencyPhone']),
                  );
                },
              ),
      ),
    );
  }
}

// ─── Card content ────────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final String name;
  final String duration;
  final String phone;
  final String emergencyPhone;

  const _CardContent({
    required this.name,
    required this.duration,
    required this.phone,
    required this.emergencyPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + duration badge
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duration,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        const SizedBox(height: 12),
        _phoneRow(context, 'PHONE', phone),
        const SizedBox(height: 8),
        _phoneRow(context, 'EMERGENCY', emergencyPhone),
      ],
    );
  }

  Widget _phoneRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
        if (value != '---')
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              AppSnackbar.showInfo(
                context,
                '$label copied',
                duration: const Duration(milliseconds: 800),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
      ],
    );
  }
}
