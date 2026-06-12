import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/models/test_result.dart';
import '../data/repositories/content_repository.dart';
import '../data/repositories/firestore_progress_repository.dart';
import '../data/repositories/progress_repository.dart';

// ---- Repozitoriylar ----
final contentRepoProvider =
    Provider<ContentRepository>((ref) => LocalContentRepository());

// Offline-first: lokal SharedPreferences + Firestore mirror.
final progressRepoProvider = Provider<ProgressRepository>(
  (ref) => FirestoreSyncProgressRepository(
    local: SharedPrefsProgressRepository(),
    db: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  ),
);

// ---- Kontent ----
final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final repo = ref.watch(contentRepoProvider);
  return repo.loadTopics();
});

// ---- Mavzu nishonlari (badge) ----
const kBadgeFirst = 'first';
const kBadgePerfect = 'perfect';
const kBadgeHalf = 'half';
const kBadgeStreak7 = 'streak7';
const kBadgeCertificate = 'certificate';

class BadgeInfo {
  final String key;
  final String label;
  final IconData icon;
  const BadgeInfo(this.key, this.label, this.icon);
}

const kAllBadges = <BadgeInfo>[
  BadgeInfo(kBadgeFirst, 'Birinchi qadam', Icons.emoji_events_rounded),
  BadgeInfo(kBadgePerfect, 'Mukammal test', Icons.workspace_premium_rounded),
  BadgeInfo(kBadgeHalf, 'Yarmi tamom', Icons.rocket_launch_rounded),
  BadgeInfo(kBadgeStreak7, '7 kun streak', Icons.local_fire_department_rounded),
  BadgeInfo(kBadgeCertificate, 'Sertifikat', Icons.card_membership_rounded),
];

// ---- Tungi rejim ----
final themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);

// ---- Progress holati ----
class ProgressState {
  final Map<int, TopicProgress> topics;
  final int points;
  final Set<String> badges;
  final int streak;
  final int topicCount;
  final bool loaded;
  final String studentName;

  const ProgressState({
    required this.topics,
    required this.points,
    required this.badges,
    required this.streak,
    required this.topicCount,
    required this.loaded,
    this.studentName = '',
  });

  factory ProgressState.initial() => const ProgressState(
        topics: {},
        points: 0,
        badges: {},
        streak: 1,
        topicCount: 8,
        loaded: false,
        studentName: '',
      );

  bool get hasCertificate => badges.contains(kBadgeCertificate);

  TopicProgress progressFor(int topicId) =>
      topics[topicId] ?? TopicProgress();

  int get completedTopics =>
      topics.values.where((p) => p.isCompleted).length;

  int get overallPercent {
    if (topicCount == 0) return 0;
    var sum = 0;
    for (var i = 1; i <= topicCount; i++) {
      sum += (topics[i]?.percent ?? 0);
    }
    return (sum / topicCount).round();
  }

  /// 1-mavzu doim ochiq; mavzu n oldingisi yakunlansa ochiladi.
  bool isUnlocked(int topicId) {
    if (topicId <= 1) return true;
    final prev = topics[topicId - 1];
    return prev != null && prev.isCompleted;
  }

  ProgressState copyWith({
    Map<int, TopicProgress>? topics,
    int? points,
    Set<String>? badges,
    int? streak,
    bool? loaded,
    String? studentName,
  }) =>
      ProgressState(
        topics: topics ?? this.topics,
        points: points ?? this.points,
        badges: badges ?? this.badges,
        streak: streak ?? this.streak,
        topicCount: topicCount,
        loaded: loaded ?? this.loaded,
        studentName: studentName ?? this.studentName,
      );
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final ProgressRepository repo;
  ProgressNotifier(this.repo) : super(ProgressState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final data = await repo.load();
    state = state.copyWith(
      topics: data.topics,
      points: data.points,
      badges: data.badges,
      streak: data.streak,
      loaded: true,
      studentName: data.studentName,
    );
  }

  Future<void> _persist() async {
    await repo.save(ProgressData(
      topics: state.topics,
      points: state.points,
      badges: state.badges,
      streak: state.streak,
      studentName: state.studentName,
    ));
  }

  void setStudentName(String name) {
    state = state.copyWith(studentName: name);
    _persist();
  }

  TopicProgress _mutableCopy(int topicId) {
    final src = state.progressFor(topicId);
    return TopicProgress(
      video: src.video,
      lesson: src.lesson,
      test: src.test,
      testScorePct: src.testScorePct,
    );
  }

  Map<int, TopicProgress> _withUpdated(int topicId, TopicProgress tp) {
    final map = Map<int, TopicProgress>.from(state.topics);
    map[topicId] = tp;
    return map;
  }

  /// Video yoki dars bosqichini yakunlash (+10 ball).
  void completeStage(int topicId, {required bool isVideo}) {
    final tp = _mutableCopy(topicId);
    var added = 0;
    if (isVideo && !tp.video) {
      tp.video = true;
      added = 10;
    } else if (!isVideo && !tp.lesson) {
      tp.lesson = true;
      added = 10;
    }
    if (added == 0) return;
    final newTopics = _withUpdated(topicId, tp);
    final badges = Set<String>.from(state.badges);
    final tempState = state.copyWith(topics: newTopics);
    if (tempState.completedTopics == tempState.topicCount &&
        tempState.overallPercent >= 90) {
      badges.add(kBadgeCertificate);
    }
    state = state.copyWith(
      topics: newTopics,
      points: state.points + added,
      badges: badges,
    );
    _persist();
  }

  /// Testni topshirish. Natija foizi qaytadi.
  /// 60% dan yuqori bo'lsa test bosqichi yakunlangan hisoblanadi.
  int submitTest(int topicId, int correct, int total) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final tp = _mutableCopy(topicId);
    final firstPass = pct >= 60 && !tp.test;
    if (pct >= 60) {
      tp.test = true;
    }
    tp.testScorePct = pct;

    var points = state.points;
    if (firstPass) points += correct * 5;

    final badges = Set<String>.from(state.badges);
    final topics = _withUpdated(topicId, tp);

    // Nishonlar
    if (tp.isCompleted) badges.add(kBadgeFirst);
    if (pct == 100) badges.add(kBadgePerfect);
    final completed = topics.values.where((p) => p.isCompleted).length;
    if (completed >= 4) badges.add(kBadgeHalf);
    if (state.streak >= 7) badges.add(kBadgeStreak7);
    final tempState = state.copyWith(topics: topics);
    if (tempState.completedTopics == tempState.topicCount &&
        tempState.overallPercent >= 90) {
      badges.add(kBadgeCertificate);
    }

    state = state.copyWith(
      topics: topics,
      points: points,
      badges: badges,
    );
    _persist();
    // Har bir test natijasini alohida saqlash (Firestore: results/{topicId}).
    repo.saveTestResult(TestResult(
      topicId: topicId,
      scorePct: pct,
      correct: correct,
      total: total,
      date: DateTime.now(),
    ));
    return pct;
  }

  Future<void> reset() async {
    await repo.clear();
    state = state.copyWith(
      topics: {},
      points: 0,
      badges: <String>{},
      streak: 1,
    );
  }
}

final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(ref.watch(progressRepoProvider));
});
