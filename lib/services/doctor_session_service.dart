import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get doctorId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _activeSessionRef(String uid) {
    return _firestore.collection('doctor_active_sessions').doc(uid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> activeSessionStream() {
    final uid = doctorId;
    if (uid == null) {
      return const Stream.empty();
    }
    return _activeSessionRef(uid).snapshots();
  }

  Future<void> startSession({
    required String patientId,
    required String patientName,
  }) async {
    final uid = doctorId;
    if (uid == null) {
      throw Exception('Doctor not logged in');
    }

    final now = FieldValue.serverTimestamp();
    await _activeSessionRef(uid).set({
      'doctorId': uid,
      'patientId': patientId,
      'patientName': patientName,
      'startedAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> endSession() async {
    final uid = doctorId;
    if (uid == null) {
      throw Exception('Doctor not logged in');
    }

    final activeRef = _activeSessionRef(uid);
    final activeSnap = await activeRef.get();
    if (!activeSnap.exists) {
      return;
    }

    final activeData = activeSnap.data() ?? {};
    await _firestore.collection('doctor_sessions').add({
      'doctorId': uid,
      'patientId': activeData['patientId'] ?? '',
      'patientName': activeData['patientName'] ?? 'Unknown Patient',
      'startedAt': activeData['startedAt'],
      'endedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await activeRef.delete();
  }
}
