import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final AppUser? profile;

  const AuthState({required this.status, this.user, this.profile});

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => profile?.role == 'admin';
  String? get email => user?.email;
}

/// Firebase auth holatini kuzatadi va kirgan userning profilini (role) yuklaydi.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repo;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  AuthNotifier(this.repo) : super(AuthState.loading()) {
    _authSub = repo.authState().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    // Avvalgi foydalanuvchining profil oqimini to'xtatamiz.
    _profileSub?.cancel();
    _profileSub = null;

    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    // Realtime profil: role serverda o'zgarsa (student → admin) darhol
    // aks etadi. Bir martalik get() mobil keshdan eski rolni qaytarardi.
    _profileSub = repo.profileStream(user.uid).listen(
      (profile) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
        );
      },
      onError: (_) {
        // Profil o'qilmasa ham, kirgan deb hisoblaymiz (student sifatida).
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: null,
        );
      },
    );
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepoProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepoProvider)),
);

final isAdminProvider = Provider<bool>((ref) => ref.watch(authProvider).isAdmin);
