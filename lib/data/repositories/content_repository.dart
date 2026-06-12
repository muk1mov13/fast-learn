import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// Abstrakt interfeys — keyin Firebase implementatsiyasini qo'shish oson bo'lsin.
abstract class ContentRepository {
  Future<List<Topic>> loadTopics();
}

/// Lokal (assets) implementatsiya: topic_1.json ... topic_8.json.
class LocalContentRepository implements ContentRepository {
  static const int topicCount = 8;

  @override
  Future<List<Topic>> loadTopics() async {
    final topics = <Topic>[];
    for (var i = 1; i <= topicCount; i++) {
      final raw = await rootBundle.loadString('assets/content/topic_$i.json');
      topics.add(Topic.parse(raw));
    }
    topics.sort((a, b) => a.order.compareTo(b.order));
    return topics;
  }
}
