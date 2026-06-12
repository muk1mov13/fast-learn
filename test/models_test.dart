import 'package:flutter_test/flutter_test.dart';
import 'package:texnik_ijodkorlik/data/models/models.dart';

void main() {
  group('VideoItem.fromJson', () {
    test('youtubeId ni to\'g\'ri o\'qiydi', () {
      final item = VideoItem.fromJson({
        'title': 'Test video',
        'duration': '5:00',
        'youtubeId': 'dQw4w9WgXcQ',
      });
      expect(item.title, 'Test video');
      expect(item.duration, '5:00');
      expect(item.youtubeId, 'dQw4w9WgXcQ');
    });

    test('youtubeId yo\'q bo\'lsa bo\'sh string qaytaradi', () {
      final item = VideoItem.fromJson({'title': 'Test', 'duration': ''});
      expect(item.youtubeId, '');
    });
  });

  group('ResourceItem.fromJson', () {
    test('barcha fieldlarni to\'g\'ri o\'qiydi', () {
      final item = ResourceItem.fromJson({
        'title': 'Texnik ijodkorlik asoslari',
        'type': 'book',
        'description': 'Asosiy darslik',
        'url': '',
      });
      expect(item.title, 'Texnik ijodkorlik asoslari');
      expect(item.type, 'book');
      expect(item.description, 'Asosiy darslik');
      expect(item.url, '');
    });

    test('yo\'q fieldlar uchun default qaytaradi', () {
      final item = ResourceItem.fromJson({});
      expect(item.title, '');
      expect(item.type, 'link');
      expect(item.description, '');
      expect(item.url, '');
    });
  });

  group('Topic.fromJson resources', () {
    test('resources listni to\'g\'ri parse qiladi', () {
      final topic = Topic.fromJson({
        'id': 1,
        'order': 1,
        'title': 'Test',
        'isUnlocked': true,
        'video': {'title': 'v', 'duration': '', 'youtubeId': ''},
        'lesson': {'title': 'l', 'bodyMarkdown': '', 'slideTitles': []},
        'glossary': [],
        'crossword': [],
        'questions': [],
        'practical': {'task': '', 'requirement': ''},
        'test': [],
        'resources': [
          {'title': 'Kitob 1', 'type': 'book', 'description': 'desc', 'url': ''},
        ],
      });
      expect(topic.resources.length, 1);
      expect(topic.resources.first.title, 'Kitob 1');
    });

    test('resources field yo\'q bo\'lsa bo\'sh list qaytaradi', () {
      final topic = Topic.fromJson({
        'id': 1,
        'order': 1,
        'title': 'Test',
        'isUnlocked': true,
        'video': {'title': 'v', 'duration': '', 'youtubeId': ''},
        'lesson': {'title': 'l', 'bodyMarkdown': '', 'slideTitles': []},
        'glossary': [],
        'crossword': [],
        'questions': [],
        'practical': {'task': '', 'requirement': ''},
        'test': [],
      });
      expect(topic.resources, isEmpty);
    });
  });
}
