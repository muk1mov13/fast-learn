import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/models/test_result.dart';
import '../data/repositories/admin_repository.dart';
import 'auth_providers.dart';

final adminRepoProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(firestoreProvider)),
);

/// Barcha foydalanuvchilar (real-time).
final usersStreamProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(adminRepoProvider).watchUsers(),
);

/// Bitta foydalanuvchi profili (real-time).
final userByIdProvider =
    StreamProvider.autoDispose.family<AppUser?, String>(
  (ref, uid) => ref.watch(adminRepoProvider).watchUser(uid),
);

/// Foydalanuvchining test natijalari (real-time).
final userResultsProvider =
    StreamProvider.autoDispose.family<List<TestResult>, String>(
  (ref, uid) => ref.watch(adminRepoProvider).watchResults(uid),
);
