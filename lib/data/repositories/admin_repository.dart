import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/test_result.dart';

/// Admin paneli uchun Firestore'dan o'qish (faqat admin huquqida ishlaydi).
class AdminRepository {
  final FirebaseFirestore db;
  AdminRepository(this.db);

  Stream<List<AppUser>> watchUsers() => db
      .collection('users')
      .snapshots()
      .map((snap) => snap.docs.map(AppUser.fromDoc).toList());

  Stream<AppUser?> watchUser(String uid) => db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Stream<List<TestResult>> watchResults(String uid) => db
      .collection('users')
      .doc(uid)
      .collection('results')
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((d) => TestResult.fromMap(d.data())).toList();
        list.sort((a, b) => a.topicId.compareTo(b.topicId));
        return list;
      });
}
