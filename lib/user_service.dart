
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserRecord({
    required User user,
    required String firstName,
    required String lastName,
  }) async {
    final ref = _db.collection('users').doc(user.uid);

    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);

      if (existing.exists) return;

      transaction.set(ref, {
        'uid': user.uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'role': 'member',
        'registrationDateTime': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<Map<String, dynamic>?> watchUserRecord(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
      (snapshot) => snapshot.data(),
    );
  }

  bool isComplete(Map<String, dynamic> data, String uid) {
    return data['uid'] == uid &&
        data['firstName'] is String &&
        (data['firstName'] as String).trim().isNotEmpty &&
        data['lastName'] is String &&
        (data['lastName'] as String).trim().isNotEmpty &&
        data['role'] is String &&
        (data['role'] as String).trim().isNotEmpty &&
        data['registrationDateTime'] is Timestamp;
  }
}
