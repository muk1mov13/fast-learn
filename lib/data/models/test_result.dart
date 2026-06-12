import 'package:cloud_firestore/cloud_firestore.dart';

/// Bitta mavzu bo'yicha test natijasi — Firestore `users/{uid}/results/{topicId}`.
class TestResult {
  final int topicId;
  final int scorePct;
  final int correct;
  final int total;
  final DateTime date;

  const TestResult({
    required this.topicId,
    required this.scorePct,
    required this.correct,
    required this.total,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'topicId': topicId,
        'scorePct': scorePct,
        'correct': correct,
        'total': total,
        'date': Timestamp.fromDate(date),
      };

  factory TestResult.fromMap(Map<String, dynamic> j) => TestResult(
        topicId: (j['topicId'] ?? 0) as int,
        scorePct: (j['scorePct'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
        total: (j['total'] ?? 0) as int,
        date: j['date'] is Timestamp
            ? (j['date'] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}
