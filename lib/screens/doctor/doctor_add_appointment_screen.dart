import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/utils/app_snackbar.dart';
import 'package:my_app/widgets/healthsnap_logo_title.dart';

class DoctorAddAppointmentScreen extends StatefulWidget {
  final String? appointmentDocId;
  final String? initialPatientName;
  final DateTime? initialScheduledAt;
  final int? initialDurationMinutes;

  const DoctorAddAppointmentScreen({
    super.key,
    this.appointmentDocId,
    this.initialPatientName,
    this.initialScheduledAt,
    this.initialDurationMinutes,
  });

  bool get isEditing => appointmentDocId != null;

  @override
  State<DoctorAddAppointmentScreen> createState() =>
      _DoctorAddAppointmentScreenState();
}

class _DoctorAddAppointmentScreenState
    extends State<DoctorAddAppointmentScreen> {
  final _nameController = TextEditingController();
  TimeOfDay? _selectedTime;
  int _selectedDuration = 30;
  bool _isLoading = false;

  final List<int> _durations = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialPatientName ?? '';

    if (widget.initialScheduledAt != null) {
      _selectedTime = TimeOfDay.fromDateTime(
        widget.initialScheduledAt!.toLocal(),
      );
    }

    final initialDuration = widget.initialDurationMinutes;
    if (initialDuration != null && _durations.contains(initialDuration)) {
      _selectedDuration = initialDuration;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF3B5BDB)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter patient name');
      return;
    }
    if (_selectedTime == null) {
      _showError('Please select a start time');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doctorId = FirebaseAuth.instance.currentUser?.uid;
      if (doctorId == null) throw Exception('Not logged in');

      final now = DateTime.now();
      final scheduledAt = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (widget.isEditing) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentDocId)
            .update({
              'patientName': name,
              'scheduledAt': Timestamp.fromDate(scheduledAt),
              'durationMinutes': _selectedDuration,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance.collection('appointments').add({
          'doctorId': doctorId,
          'patientName': name,
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'durationMinutes': _selectedDuration,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    AppSnackbar.showError(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 14,
        title: const HealthsnapLogoTitle(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text(
              widget.isEditing ? 'Edit Consultation' : 'New Consultation',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Schedule a new session for your patient.\nAll fields are required for the clinical record.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Patient Name
            _label('Patient Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. John Doe',
                hintStyle: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Start Time
            _label('Start Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _selectedTime == null
                        ? '--:-- --'
                        : _formatTime(_selectedTime!),
                    hintStyle: TextStyle(
                      color: _selectedTime == null
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: _selectedTime != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.access_time,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Duration
            _label('Duration'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedDuration,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                  items: _durations
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d Minutes'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDuration = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.isEditing ? Icons.save_outlined : Icons.add,
                        size: 20,
                      ),
                label: Text(
                  widget.isEditing ? 'Save Changes' : 'Add Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BDB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: const Color(0xFFEFF3FF),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}
