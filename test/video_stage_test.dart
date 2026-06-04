import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:texnik_ijodkorlik/data/models/models.dart';
import 'package:texnik_ijodkorlik/features/topic/stages/video_stage.dart';

Topic _emptyVideoTopic() => const Topic(
      id: 1,
      order: 1,
      title: 'Test',
      baseUnlocked: true,
      video: VideoItem(title: '', duration: '', assetPath: ''),
      lesson: Lesson(title: '', bodyMarkdown: '', slideTitles: []),
      glossary: [],
      crossword: [],
      questions: [],
      practical: PracticalTask(task: '', requirement: ''),
      test: [],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('VideoStage watch gate', () {
    testWidgets('tapping button without watching does not complete stage',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: VideoStage(topic: _emptyVideoTopic())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button is present (may be below fold — scroll it into view)
      final btnFinder = find.text('Videoni yakunlash (+10 ball)', skipOffstage: false);
      expect(btnFinder, findsOneWidget);
      await tester.scrollUntilVisible(btnFinder, 50);
      await tester.pumpAndSettle();

      // Tap it — should do nothing because 0% watched
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Completed card must NOT appear
      expect(find.text('Bu bosqich yakunlangan'), findsNothing);
    });

    testWidgets('no progress text when assetPath is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: VideoStage(topic: _emptyVideoTopic())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Per spec: no progress label when there is no video file
      expect(find.textContaining("% ko'rildi"), findsNothing);
    });
  });
}
