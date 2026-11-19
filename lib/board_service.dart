
import 'package:cloud_firestore/cloud_firestore.dart';

class BoardMessage {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime? createdAt;
  final DateTime? editedAt;

  BoardMessage({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.editedAt,
  });
}

class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CREATE
  Future<void> postMessage({
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    final value = text.trim();

    if (value.isEmpty || value.length > 500) {
      throw ArgumentError('Message must be 1-500 characters.');
    }

    await _db.collection('messages').add({
      'text': value,
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ - Live Firestore stream
  Stream<List<BoardMessage>> messageBoard() {
    return _db
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final created = data['createdAt'];
        final edited = data['editedAt'];

        return BoardMessage(
          id: doc.id,
          text: data['text'] as String? ?? '',
          authorUid: data['authorUid'] as String? ?? '',
          authorName: data['authorName'] as String? ?? 'Unknown',
          createdAt:
              created is Timestamp ? created.toDate() : null,
          editedAt:
              edited is Timestamp ? edited.toDate() : null,
        );
      }).toList();
    });
  }

  // UPDATE
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    final value = newText.trim();

    if (value.isEmpty || value.length > 500) {
      throw ArgumentError('Message must be 1-500 characters.');
    }

    await _db.collection('messages').doc(messageId).update({
      'text': value,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // DELETE
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    await _db.collection('messages').doc(messageId).delete();
  }
}
