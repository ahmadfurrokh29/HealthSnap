import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/doctor/doctor_end_session_screen.dart';
import 'package:my_app/screens/doctor/doctor_qr_scan_screen.dart';
import 'package:my_app/screens/doctor/widgets/doctor_app_bar.dart';
import 'package:my_app/services/doctor_session_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  final VoidCallback onOpenPatients;
  final VoidCallback onOpenSchedule;

  const DoctorHomeScreen({
    super.key,
    required this.onOpenPatients,
    required this.onOpenSchedule,
  });

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final String? _doctorId = FirebaseAuth.instance.currentUser?.uid;
  final DoctorSessionService _sessionService = DoctorSessionService();

  Timer? _timer;

  // Streams stored once so StreamBuilder never re-subscribes on timer setState
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _completedSessionsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _appointmentsStream;

  @override
  void initState() {
    super.initState();
    final doctorId = _doctorId;
    if (doctorId != null) {
      _completedSessionsStream = FirebaseFirestore.instance
          .collection('doctor_sessions')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots();
      _appointmentsStream = FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots();
    } else {
      _completedSessionsStream = const Stream.empty();
      _appointmentsStream = const Stream.empty();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _todayStart => DateUtils.dateOnly(DateTime.now());

  DateTime get _todayEnd =>
      DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatRemaining(Duration diff) {
    if (diff.isNegative) {
      return 'Started';
    }
    if (diff.inHours > 0) {
      return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes < 1) {
      return 'In <1 min';
    }
    return 'In ${diff.inMinutes} mins';
  }

  String _sessionElapsed(Timestamp? startedAt) {
    if (startedAt == null) {
      return '--:--';
    }
    final diff = DateTime.now().difference(startedAt.toDate());
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  DateTime? _readScheduledAt(Map<String, dynamic> data) {
    final raw = data['scheduledAt'];
    if (raw is Timestamp) {
      return raw.toDate().toLocal();
    }
    if (raw is DateTime) {
      return raw.toLocal();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = _doctorId;

    if (doctorId == null) {
      return const Scaffold(body: Center(child: Text('Doctor not logged in')));
    }

    // Use pre-built streams from initState — not re-created on each build

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const DoctorAppBar(confirmLogout: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Hello Doctor',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "We've prepared your schedule for today.",
              style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _completedSessionsStream,
                    builder: (context, snapshot) {
                      final allDocs = snapshot.data?.docs ?? [];
                      // Filter client-side so stream reference never changes
                      final count = allDocs.where((doc) {
                        final raw = doc.data()['endedAt'];
                        if (raw is! Timestamp) return false;
                        final dt = raw.toDate().toLocal();
                        return !dt.isBefore(_todayStart) &&
                            !dt.isAfter(_todayEnd);
                      }).length;
                      return _smallInfoCard(
                        onTap: widget.onOpenSchedule,
                        bgColor: const Color(0xFFEEF2FF),
                        title: 'Total Patients\nToday',
                        value: '$count',
                        icon: Icons.groups_2_outlined,
                        iconColor: const Color(0xFF3B5BDB),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _appointmentsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _smallInfoCard(
                          onTap: widget.onOpenSchedule,
                          bgColor: const Color(0xFFE6F4EA),
                          title: 'Next\nAppointment',
                          value: '--:--',
                          subtitle: 'Unable to load',
                          icon: Icons.access_time,
                          iconColor: const Color(0xFF2E7D32),
                          valueFontSize: 26,
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final now = DateTime.now();
                      Map<String, dynamic>? nextData;
                      DateTime? nextTime;

                      for (final doc in docs) {
                        final data = doc.data();
                        final scheduledAt = _readScheduledAt(data);
                        if (scheduledAt == null || scheduledAt.isBefore(now)) {
                          continue;
                        }
                        if (nextTime == null ||
                            scheduledAt.isBefore(nextTime)) {
                          nextTime = scheduledAt;
                          nextData = data;
                        }
                      }

                      final hasNext = nextTime != null;
                      final nextDateTime = nextTime;
                      final remaining = hasNext
                          ? _formatRemaining(nextDateTime!.difference(now))
                          : 'No appointment';
                      final patientName = hasNext
                          ? ((nextData?['patientName']?.toString()) ??
                                'Patient')
                          : '';

                      return _smallInfoCard(
                        onTap: widget.onOpenSchedule,
                        bgColor: const Color(0xFFE6F4EA),
                        title: 'Next\nAppointment',
                        value: hasNext ? _formatTime(nextDateTime!) : '--:--',
                        subtitle: hasNext
                            ? '$patientName • $remaining'
                            : remaining,
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF2E7D32),
                        valueFontSize: 26,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _scanQrCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorQrScanScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _appointmentsStream,
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final now = DateTime.now();
                      final remainingSlots = docs.where((doc) {
                        final scheduledAt = _readScheduledAt(doc.data());
                        if (scheduledAt == null) {
                          return false;
                        }
                        return !scheduledAt.isBefore(_todayStart) &&
                            scheduledAt.isBefore(_todayEnd) &&
                            scheduledAt.isAfter(now);
                      }).length;

                      return _actionCard(
                        onTap: widget.onOpenSchedule,
                        title: 'My\nAppointments',
                        subtitle: '$remainingSlots slots remaining',
                        bgColor: const Color(0xFF75A468),
                        icon: Icons.calendar_today_outlined,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _sessionService.activeSessionStream(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                if (data == null) {
                  return _noPatientCard();
                }

                final patientName =
                    data['patientName']?.toString() ?? 'Unknown Patient';
                final patientId = data['patientId']?.toString() ?? '---';
                final startedAt = data['startedAt'] as Timestamp?;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: $patientId',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sessionElapsed(startedAt),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onOpenPatients,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B5BDB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Open Patient Profile',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const DoctorEndSessionScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.block, size: 16),
                              label: const Text('End Session'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB42318),
                                side: const BorderSide(
                                  color: Color(0xFFE5C2C2),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _smallInfoCard({
    required VoidCallback onTap,
    required Color bgColor,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    double valueFontSize = 48,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Icon(icon, size: 18, color: iconColor),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: iconColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scanQrCard({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B5BDB),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scan Patient QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required Color bgColor,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.white, size: 24),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE5E7EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _noPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Current Patient',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No patient',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
