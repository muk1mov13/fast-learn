import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Firebase Authentication + Firestore `users/{uid}` ustidagi o'ram.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepository(this._auth, this._db);

  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  /// Yangi foydalanuvchi yaratadi va `users/{uid}` hujjatini boshlang'ich
  /// qiymatlar bilan to'ldiradi (role har doim "student").
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(fullName.trim());
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'totalPoints': 0,
      'completedTopics': 0,
      'overallPercent': 0,
      'certificateEarned': false,
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// `users/{uid}` hujjatini realtime kuzatadi. Bir martalik `.get()` mobil
  /// keshdan eski rolni qaytarishi mumkin; snapshots() esa serverdagi
  /// o'zgarishni (masalan role: student → admin) darhol yetkazadi.
  Stream<AppUser?> profileStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
}

/// FirebaseAuthException kodlarini o'zbekcha xabarlarga aylantiradi.
String authErrorMessage(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return "Email manzil noto'g'ri formatda.";
      case 'user-disabled':
        return 'Bu hisob bloklangan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Email yoki parol noto'g'ri.";
      case 'email-already-in-use':
        return "Bu email allaqachon ro'yxatdan o'tgan.";
      case 'weak-password':
        return 'Parol juda zaif (kamida 6 belgi).';
      case 'network-request-failed':
        return 'Internet aloqasi yo\'q. Ulanishni tekshiring.';
      case 'too-many-requests':
        return "Juda ko'p urinish. Birozdan so'ng qayta urinib ko'ring.";
      default:
        return 'Xatolik yuz berdi. Qayta urinib ko\'ring.';
    }
  }
  return 'Xatolik yuz berdi. Qayta urinib ko\'ring.';
}
