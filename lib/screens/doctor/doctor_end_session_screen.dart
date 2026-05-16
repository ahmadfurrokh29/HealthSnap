import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_app/services/doctor_session_service.dart';
import 'package:my_app/utils/app_snackbar.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';

class DoctorEndSessionScreen extends StatefulWidget {
  const DoctorEndSessionScreen({super.key});

  @override
  State<DoctorEndSessionScreen> createState() => _DoctorEndSessionScreenState();
}

class _DoctorEndSessionScreenState extends State<DoctorEndSessionScreen> {
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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

  String _formatDuration(Timestamp? startedAt) {
    if (startedAt == null) {
      return '--';
    }
    final diff = DateTime.now().difference(startedAt.toDate());
    final mins = diff.inMinutes;
    final secs = diff.inSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  Future<void> _confirmEndSession() async {
    setState(() => _isLoading = true);

    try {
      await DoctorSessionService().endSession();
      if (!mounted) {
        return;
      }
      AppSnackbar.showSuccess(context, 'Session ended successfully');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackbar.showError(
          context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const HealthsnapLogoTitle(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF83B590)),
                SizedBox(width: 6),
                Text(
                  'ACTIVE SESSION',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: DoctorSessionService().activeSessionStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final patientName =
              data?['patientName']?.toString() ?? 'Unknown Patient';
          final startedAt = data?['startedAt'] as Timestamp?;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              children: [
                const Text(
                  'Confirm Session\nEnd',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52 / 2,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to end this\npatient session? All temporary data will\nbe cleared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 26),
                _infoBox('PATIENT NAME', patientName),
                const SizedBox(height: 12),
                _infoBox('DURATION', _formatDuration(startedAt)),
                const SizedBox(height: 32),
                _dashedWrap(
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmEndSession,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFB42318),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Yes, End Session',
                              style: TextStyle(
                                fontSize: 30 / 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _dashedWrap(
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        elevation: 0,
                        foregroundColor: const Color(0xFF5B6472),
                        backgroundColor: const Color(0xFFE9EEF5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 30 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'By ending the session, all unsynced diagnostics\nand temporary cache will be permanently\ndeleted from this local device to ensure HIPAA\ncompliance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 33 / 2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedWrap({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFF8DA9D6), width: 1.4),
      ),
      child: child,
    );
  }
}
