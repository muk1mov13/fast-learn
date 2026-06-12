import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `users/{uid}` hujjatidagi foydalanuvchi profili.
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role; // "student" | "admin"
  final DateTime? createdAt;
  final DateTime? lastActive;
  final int totalPoints;
  final int completedTopics;
  final int overallPercent;
  final bool certificateEarned;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.createdAt,
    this.lastActive,
    this.totalPoints = 0,
    this.completedTopics = 0,
    this.overallPercent = 0,
    this.certificateEarned = false,
  });

  bool get isAdmin => role == 'admin';

  static DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;
  static int _toInt(dynamic v) => v is num ? v.toInt() : 0;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      fullName: (j['fullName'] ?? '') as String,
      email: (j['email'] ?? '') as String,
      role: (j['role'] ?? 'student') as String,
      createdAt: _toDate(j['createdAt']),
      lastActive: _toDate(j['lastActive']),
      totalPoints: _toInt(j['totalPoints']),
      completedTopics: _toInt(j['completedTopics']),
      overallPercent: _toInt(j['overallPercent']),
      certificateEarned: (j['certificateEarned'] ?? false) as bool,
    );
  }
}
