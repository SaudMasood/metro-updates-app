import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final _db = FirebaseFirestore.instance;

  Future addUpdate(String message) async {
    await _db.collection('updates').add({
      'message': message,
      'time': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUpdates() {
    return _db
        .collection('updates')
        .orderBy('time', descending: true)
        .snapshots();
  }

  Future deleteUpdate(String docId) async {
    await _db.collection('updates').doc(docId).delete();
  }
}