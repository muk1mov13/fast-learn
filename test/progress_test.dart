import 'package:flutter_test/flutter_test.dart';
import 'package:texnik_ijodkorlik/data/models/models.dart';
import 'package:texnik_ijodkorlik/data/repositories/progress_repository.dart';
import 'package:texnik_ijodkorlik/state/providers.dart';

class _FakeRepo extends ProgressRepository {
  ProgressData _data = ProgressData.empty();
  @override
  Future<ProgressData> load() async => _data;
  @override
  Future<void> save(ProgressData data) async => _data = data;
  @override
  Future<void> clear() async => _data = ProgressData.empty();
}

ProgressNotifier _notifier() => ProgressNotifier(_FakeRepo());

void main() {
  group('TopicProgress', () {
    test('bosh progress 0% boladi', () {
      final p = TopicProgress();
      expect(p.percent, 0);
      expect(p.isCompleted, false);
    });

    test('video + dars = 67%', () {
      final p = TopicProgress(video: true, lesson: true);
      expect(p.percent, 67);
      expect(p.isCompleted, false);
    });

    test('barcha bosqich + 60% test = yakunlangan', () {
      final p = TopicProgress(
          video: true, lesson: true, test: true, testScorePct: 80);
      expect(p.percent, 100);
      expect(p.isCompleted, true);
    });

    test('test 60% dan past bolsa yakunlanmaydi', () {
      final p = TopicProgress(
          video: true, lesson: true, test: false, testScorePct: 40);
      expect(p.isCompleted, false);
    });
  });

  group('Topic JSON parsing', () {
    test('toliq obyektni oqiydi', () {
      const src = '{'
          '"id": 1, "order": 1, "title": "Test mavzu", "isUnlocked": true,'
          '"video": {"title": "V", "duration": "01:00"},'
          '"lesson": {"title": "L", "bodyMarkdown": "matn", "slideTitles": ["a","b"]},'
          '"glossary": [{"term": "T", "definition": "D"}],'
          '"crossword": [{"orientation": "Gorizontal", "clue": "C", "answer": "ABC"}],'
          '"questions": ["savol?"],'
          '"practical": {"task": "t", "requirement": "r"},'
          '"test": [{"question": "q", "options": ["a","b","c","d"], "correctIndex": 2}]'
          '}';
      final t = Topic.parse(src);
      expect(t.id, 1);
      expect(t.title, 'Test mavzu');
      expect(t.glossary.length, 1);
      expect(t.crossword.first.answer, 'ABC');
      expect(t.test.first.correctIndex, 2);
      expect(t.hasTest, true);
    });

    test('bosh test royxatini xatosiz qabul qiladi', () {
      const src = '{"id": 8, "order": 8, "title": "X", "isUnlocked": false,'
          '"video": {}, "lesson": {}, "glossary": [], "crossword": [],'
          '"questions": [], "practical": {}, "test": []}';
      final t = Topic.parse(src);
      expect(t.hasTest, false);
      expect(t.test, isEmpty);
    });
  });

  group('ProgressNotifier.submitTest', () {
    test('6/10 → 60%, test=true (otdi)', () {
      final n = _notifier();
      final pct = n.submitTest(1, 6, 10);
      expect(pct, 60);
      expect(n.state.topics[1]?.test, true);
      expect(n.state.topics[1]?.testScorePct, 60);
    });

    test('5/10 → 50%, test=false (otmadi)', () {
      final n = _notifier();
      final pct = n.submitTest(1, 5, 10);
      expect(pct, 50);
      expect(n.state.topics[1]?.test, false);
      expect(n.state.topics[1]?.testScorePct, 50);
    });

    test('10/10 → 100%, test=true', () {
      final n = _notifier();
      final pct = n.submitTest(1, 10, 10);
      expect(pct, 100);
      expect(n.state.topics[1]?.test, true);
    });

    test('total=0 bolsa 0% qaytaradi', () {
      final n = _notifier();
      final pct = n.submitTest(1, 0, 0);
      expect(pct, 0);
    });

    test('birinchi muvaffaqiyat correct x5 ball beradi', () {
      final n = _notifier();
      n.submitTest(1, 8, 10);
      expect(n.state.points, 8 * 5);
    });

    test('qayta urinish qoshimcha ball bermaydi', () {
      final n = _notifier();
      n.submitTest(1, 8, 10);
      final pointsAfterFirst = n.state.points;
      n.submitTest(1, 10, 10);
      expect(n.state.points, pointsAfterFirst);
    });

    test('100% → perfect badge', () {
      final n = _notifier();
      n.submitTest(1, 10, 10);
      expect(n.state.badges, contains(kBadgePerfect));
    });

    test('mavzu yakunlanganda first badge', () {
      final n = _notifier();
      n.completeStage(1, isVideo: true);
      n.completeStage(1, isVideo: false);
      n.submitTest(1, 8, 10);
      expect(n.state.badges, contains(kBadgeFirst));
    });
  });

  group('ProgressState.isUnlocked', () {
    test('1-mavzu doim ochiq', () {
      expect(ProgressState.initial().isUnlocked(1), true);
    });

    test('2-mavzu 1-mavzu yakunlanmasa yopiq', () {
      expect(ProgressState.initial().isUnlocked(2), false);
    });

    test('2-mavzu 1-mavzu yakunlanganda ochiladi', () {
      final n = _notifier();
      n.completeStage(1, isVideo: true);
      n.completeStage(1, isVideo: false);
      n.submitTest(1, 8, 10);
      expect(n.state.isUnlocked(2), true);
    });

    test('3-mavzu 2-mavzu yakunlanmasa yopiq', () {
      final n = _notifier();
      n.completeStage(1, isVideo: true);
      n.completeStage(1, isVideo: false);
      n.submitTest(1, 8, 10);
      expect(n.state.isUnlocked(3), false);
    });
  });

  group('ProgressNotifier.completeStage', () {
    test('video birinchi marta +10 ball', () {
      final n = _notifier();
      n.completeStage(1, isVideo: true);
      expect(n.state.points, 10);
    });

    test('video ikkinchi marta ball qoshilmaydi', () {
      final n = _notifier();
      n.completeStage(1, isVideo: true);
      n.completeStage(1, isVideo: true);
      expect(n.state.points, 10);
    });

    test('dars birinchi marta +10 ball', () {
      final n = _notifier();
      n.completeStage(1, isVideo: false);
      expect(n.state.points, 10);
    });
  });

  group('ProgressNotifier sertifikat', () {
    test('barcha 8 mavzu yakunlanib 90%+ bolsa certificate beriladi', () {
      final n = _notifier();
      for (var i = 1; i <= 8; i++) {
        n.completeStage(i, isVideo: true);
        n.completeStage(i, isVideo: false);
        n.submitTest(i, 9, 10);
      }
      expect(n.state.completedTopics, 8);
      expect(n.state.overallPercent, greaterThanOrEqualTo(90));
      expect(n.state.hasCertificate, true);
      expect(n.state.badges, contains(kBadgeCertificate));
    });

    test('7 mavzu yakunlansa certificate berilmaydi', () {
      final n = _notifier();
      for (var i = 1; i <= 7; i++) {
        n.completeStage(i, isVideo: true);
        n.completeStage(i, isVideo: false);
        n.submitTest(i, 10, 10);
      }
      expect(n.state.completedTopics, 7);
      expect(n.state.hasCertificate, false);
    });

    test('setStudentName ismi saqlaydi', () {
      final n = _notifier();
      n.setStudentName('Aliyev Bobur');
      expect(n.state.studentName, 'Aliyev Bobur');
    });
  });
}
