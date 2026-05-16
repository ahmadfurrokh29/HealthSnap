import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/screens/doctor/doctor_add_appointment_screen.dart';
import 'package:my_app/screens/doctor/doctor_past_sessions_screen.dart';
import 'package:my_app/screens/doctor/widgets/doctor_app_bar.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute so badge colours stay in sync with real time
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
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

  String _todayLabel() {
    return DateFormat('MMMM d').format(DateTime.now());
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

  Future<void> _deleteAppointment(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Appointment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this appointment?',
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
              'Delete',
              style: TextStyle(
                color: Color(0xFFE53E3E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .delete();
    }
  }

  // ── Badge colour helpers ────────────────────────────────────────────────
  Color _badgeBg(DateTime? dt, int durationMinutes) {
    if (dt == null) return const Color(0xFFEEF2FF);
    final now = DateTime.now();
    final end = dt.add(Duration(minutes: durationMinutes));
    if (now.isAfter(end)) return const Color(0xFFFFF1F1);  // past  → red
    if (now.isAfter(dt)) return const Color(0xFFE6F4EA);   // ongoing→ green
    return const Color(0xFFEEF2FF);                         // upcoming→ blue
  }

  Color _badgeTextColor(DateTime? dt, int durationMinutes) {
    if (dt == null) return const Color(0xFF3B5BDB);
    final now = DateTime.now();
    final end = dt.add(Duration(minutes: durationMinutes));
    if (now.isAfter(end)) return const Color(0xFFE53E3E);  // past  → red
    if (now.isAfter(dt)) return const Color(0xFF2E7D32);   // ongoing→ green
    return const Color(0xFF3B5BDB);                         // upcoming→ blue
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;

    if (doctorId == null) {
      return const Scaffold(body: Center(child: Text('Doctor not logged in')));
    }

    final query = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const DoctorAppBar(showLogout: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Appointments',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today, ${_todayLabel()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorPastSessionsScreen(),
                        ),
                      ),
                      child: const Text(
                        'Past sessions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B5BDB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Failed to load appointments',
                      style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final todayDocs =
                    docs.where((doc) {
                      final dt = _readScheduledAt(doc.data());
                      if (dt == null) {
                        return false;
                      }
                      return !dt.isBefore(_todayStart) &&
                          dt.isBefore(_todayEnd);
                    }).toList()..sort((a, b) {
                      final aDt = _readScheduledAt(a.data());
                      final bDt = _readScheduledAt(b.data());
                      if (aDt == null && bDt == null) {
                        return 0;
                      }
                      if (aDt == null) {
                        return 1;
                      }
                      if (bDt == null) {
                        return -1;
                      }
                      return aDt.compareTo(bDt);
                    });

                if (todayDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No appointments for today',
                      style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  itemCount: todayDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc = todayDocs[i];
                    final data = doc.data();
                    final dt = _readScheduledAt(data);
                    final patientName =
                        data['patientName']?.toString() ?? 'Unknown';
                    final duration = data['durationMinutes'] as int? ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
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
                      child: Row(
                        children: [
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      dt == null ? '--:--' : _formatTime(dt),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _badgeBg(dt, duration),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$duration MINS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _badgeTextColor(dt, duration),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DoctorAddAppointmentScreen(
                                            appointmentDocId: doc.id,
                                            initialPatientName: patientName,
                                            initialScheduledAt: dt,
                                            initialDurationMinutes: duration,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF3B5BDB),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _deleteAppointment(context, doc.id),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFE53E3E),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 54,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorAddAppointmentScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF3B5BDB),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            icon: const Icon(Icons.add, size: 22),
            label: const Text(
              'Add Appointment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
