import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/test_result.dart';

/// Progress va profilni doimiy saqlash uchun interfeys.
/// (Codegen talab qilmasligi uchun shared_preferences ishlatilgan; xohlasangiz
/// shu interfeysni Hive yoki Firestore bilan almashtirish mumkin.)
abstract class ProgressRepository {
  Future<ProgressData> load();
  Future<void> save(ProgressData data);
  Future<void> clear();

  /// Har bir test natijasini alohida saqlash uchun (default — hech narsa
  /// qilmaydi; faqat Firestore implementatsiyasi buni qo'llaydi).
  Future<void> saveTestResult(TestResult result) async {}
}

class ProgressData {
  final Map<int, TopicProgress> topics;
  final int points;
  final Set<String> badges;
  final int streak;
  final String studentName;

  ProgressData({
    required this.topics,
    required this.points,
    required this.badges,
    required this.streak,
    this.studentName = '',
  });

  factory ProgressData.empty() => ProgressData(
        topics: {},
        points: 0,
        badges: <String>{},
        streak: 1,
        studentName: '',
      );

  ProgressData copyWith({
    Map<int, TopicProgress>? topics,
    int? points,
    Set<String>? badges,
    int? streak,
    String? studentName,
  }) =>
      ProgressData(
        topics: topics ?? this.topics,
        points: points ?? this.points,
        badges: badges ?? this.badges,
        streak: streak ?? this.streak,
        studentName: studentName ?? this.studentName,
      );
}

class SharedPrefsProgressRepository extends ProgressRepository {
  static const _key = 'progress_v1';

  @override
  Future<ProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return ProgressData.empty();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final topicsJson = (j['topics'] ?? {}) as Map<String, dynamic>;
      final topics = <int, TopicProgress>{};
      topicsJson.forEach((k, v) {
        topics[int.parse(k)] =
            TopicProgress.fromJson(v as Map<String, dynamic>);
      });
      return ProgressData(
        topics: topics,
        points: (j['points'] ?? 0) as int,
        badges: ((j['badges'] as List?) ?? const [])
            .map((e) => '$e')
            .toSet(),
        streak: (j['streak'] ?? 1) as int,
        studentName: (j['studentName'] ?? '') as String,
      );
    } catch (_) {
      return ProgressData.empty();
    }
  }

  @override
  Future<void> save(ProgressData data) async {
    final prefs = await SharedPreferences.getInstance();
    final topicsJson = <String, dynamic>{};
    data.topics.forEach((k, v) => topicsJson['$k'] = v.toJson());
    final j = {
      'topics': topicsJson,
      'points': data.points,
      'badges': data.badges.toList(),
      'streak': data.streak,
      'studentName': data.studentName,
    };
    await prefs.setString(_key, jsonEncode(j));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
