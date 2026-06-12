import 'dart:convert';

/// Kontent modellari. JSON tuzilmasi assets/content/topic_N.json ga mos.

class VideoItem {
  final String title;
  final String duration;
  final String youtubeId; // YouTube (unlisted) video ID — stream uchun
  const VideoItem({
    required this.title,
    required this.duration,
    this.youtubeId = '',
  });

  factory VideoItem.fromJson(Map<String, dynamic> j) => VideoItem(
        title: (j['title'] ?? 'Mavzuga kirish videosi') as String,
        duration: (j['duration'] ?? '') as String,
        youtubeId: (j['youtubeId'] ?? '') as String,
      );
}

class Lesson {
  final String title;
  final String bodyMarkdown;
  final List<String> slideTitles;
  const Lesson({
    required this.title,
    required this.bodyMarkdown,
    required this.slideTitles,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        title: (j['title'] ?? "Ma'ruza matni") as String,
        bodyMarkdown: (j['bodyMarkdown'] ?? '') as String,
        slideTitles:
            ((j['slideTitles'] as List?) ?? const []).map((e) => '$e').toList(),
      );
}

class GlossaryTerm {
  final String term;
  final String definition;
  const GlossaryTerm({required this.term, required this.definition});

  factory GlossaryTerm.fromJson(Map<String, dynamic> j) => GlossaryTerm(
        term: (j['term'] ?? '') as String,
        definition: (j['definition'] ?? '') as String,
      );
}

class CrosswordClue {
  final String orientation;
  final String clue;
  final String answer;
  const CrosswordClue({
    required this.orientation,
    required this.clue,
    required this.answer,
  });

  factory CrosswordClue.fromJson(Map<String, dynamic> j) => CrosswordClue(
        orientation: (j['orientation'] ?? '') as String,
        clue: (j['clue'] ?? '') as String,
        answer: (j['answer'] ?? '') as String,
      );
}

class ResourceItem {
  final String title;
  final String type; // 'book', 'article', 'link', 'video'
  final String description;
  final String url;
  const ResourceItem({
    required this.title,
    required this.type,
    required this.description,
    required this.url,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> j) => ResourceItem(
        title: (j['title'] ?? '') as String,
        type: (j['type'] ?? 'link') as String,
        description: (j['description'] ?? '') as String,
        url: (j['url'] ?? '') as String,
      );
}

class PracticalTask {
  final String task;
  final String requirement;
  const PracticalTask({required this.task, required this.requirement});

  factory PracticalTask.fromJson(Map<String, dynamic> j) => PracticalTask(
        task: (j['task'] ?? '') as String,
        requirement: (j['requirement'] ?? '') as String,
      );
}

class TestQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  const TestQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> j) => TestQuestion(
        question: (j['question'] ?? '') as String,
        options:
            ((j['options'] as List?) ?? const []).map((e) => '$e').toList(),
        correctIndex: (j['correctIndex'] ?? 0) as int,
      );
}

class Topic {
  final int id;
  final int order;
  final String title;
  final bool baseUnlocked; // JSON dagi isUnlocked (boshlang'ich)
  final VideoItem video;
  final Lesson lesson;
  final List<GlossaryTerm> glossary;
  final List<CrosswordClue> crossword;
  final List<String> questions;
  final PracticalTask practical;
  final List<TestQuestion> test;
  final List<ResourceItem> resources;

  const Topic({
    required this.id,
    required this.order,
    required this.title,
    required this.baseUnlocked,
    required this.video,
    required this.lesson,
    required this.glossary,
    required this.crossword,
    required this.questions,
    required this.practical,
    required this.test,
    required this.resources,
  });

  bool get hasTest => test.isNotEmpty;

  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
        id: (j['id'] ?? 0) as int,
        order: (j['order'] ?? j['id'] ?? 0) as int,
        title: (j['title'] ?? '') as String,
        baseUnlocked: (j['isUnlocked'] ?? false) as bool,
        video: VideoItem.fromJson((j['video'] ?? {}) as Map<String, dynamic>),
        lesson: Lesson.fromJson((j['lesson'] ?? {}) as Map<String, dynamic>),
        glossary: ((j['glossary'] as List?) ?? const [])
            .map((e) => GlossaryTerm.fromJson(e as Map<String, dynamic>))
            .toList(),
        crossword: ((j['crossword'] as List?) ?? const [])
            .map((e) => CrosswordClue.fromJson(e as Map<String, dynamic>))
            .toList(),
        questions:
            ((j['questions'] as List?) ?? const []).map((e) => '$e').toList(),
        practical: PracticalTask.fromJson(
            (j['practical'] ?? {}) as Map<String, dynamic>),
        test: ((j['test'] as List?) ?? const [])
            .map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
        resources: ((j['resources'] as List?) ?? const [])
            .map((e) => ResourceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Topic parse(String source) =>
      Topic.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

/// Foydalanuvchi progressi (bitta mavzu).
class TopicProgress {
  bool video;
  bool lesson;
  bool test;
  int testScorePct;

  TopicProgress({
    this.video = false,
    this.lesson = false,
    this.test = false,
    this.testScorePct = 0,
  });

  /// Gating uchun 3 ta asosiy bosqich: video, dars, test.
  int get percent {
    final done = [video, lesson, test].where((e) => e).length;
    return (done / 3 * 100).round();
  }

  bool get isCompleted => video && lesson && test && testScorePct >= 60;

  Map<String, dynamic> toJson() => {
        'video': video,
        'lesson': lesson,
        'test': test,
        'testScorePct': testScorePct,
      };

  factory TopicProgress.fromJson(Map<String, dynamic> j) => TopicProgress(
        video: (j['video'] ?? false) as bool,
        lesson: (j['lesson'] ?? false) as bool,
        test: (j['test'] ?? false) as bool,
        testScorePct: (j['testScorePct'] ?? 0) as int,
      );
}
