import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/test_result.dart';
import 'progress_repository.dart';

/// `ProgressRepository`ni o'rab, har saqlashda lokalga (offline-first) yozadi,
/// so'ng Firestore'ga mirror qiladi. Foydalanuvchi kirmagan bo'lsa faqat
/// lokal ishlaydi — Firestore yozuvlari o'tkazib yuboriladi.
///
/// Eslatma: Firestore offline persistence yoqilgani uchun yozuvlar darhol
/// lokal cache'ga tushadi va internet ulanganda avtomatik sinxron bo'ladi.
/// `set()` Future'i offline'da yopilmasligi sababli uni `.ignore()` bilan
/// fire-and-forget qilamiz — bu save() oqimini bloklamaydi.
class FirestoreSyncProgressRepository extends ProgressRepository {
  final ProgressRepository local;
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  FirestoreSyncProgressRepository({
    required this.local,
    required this.db,
    required this.auth,
  });

  // ProgressState.topicCount bilan bir xil (8 mavzu).
  static const int _topicCount = 8;

  String? get _uid => auth.currentUser?.uid;

  @override
  Future<ProgressData> load() => local.load();

  @override
  Future<void> clear() => local.clear();

  @override
  Future<void> save(ProgressData data) async {
    await local.save(data); // 1) avval lokal — offline-first
    final uid = _uid;
    if (uid == null) return; // kirmagan: faqat lokal
    // 2) keyin Firestore summary (merge — role'ga TEGMAYDI)
    db.collection('users').doc(uid).set({
      'totalPoints': data.points,
      'completedTopics': _completedTopics(data),
      'overallPercent': _overallPercent(data),
      // kBadgeCertificate == 'certificate'
      'certificateEarned': data.badges.contains('certificate'),
      'lastActive': FieldValue.serverTimestamp(),
      if (data.studentName.isNotEmpty) 'fullName': data.studentName,
    }, SetOptions(merge: true)).ignore();
  }

  @override
  Future<void> saveTestResult(TestResult result) async {
    final uid = _uid;
    if (uid == null) return;
    db
        .collection('users')
        .doc(uid)
        .collection('results')
        .doc('${result.topicId}')
        .set(result.toMap())
        .ignore();
  }

  int _completedTopics(ProgressData d) =>
      d.topics.values.where((p) => p.isCompleted).length;

  int _overallPercent(ProgressData d) {
    var sum = 0;
    for (var i = 1; i <= _topicCount; i++) {
      sum += d.topics[i]?.percent ?? 0;
    }
    return (sum / _topicCount).round();
  }
}
