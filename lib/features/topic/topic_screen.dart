import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import 'stages/video_stage.dart';
import 'stages/lesson_stage.dart';
import 'stages/glossary_stage.dart';
import 'stages/reinforce_stages.dart';
import 'stages/test_stage.dart';

class TopicScreen extends ConsumerStatefulWidget {
  final int topicId;
  final int initialTab;
  const TopicScreen({super.key, required this.topicId, this.initialTab = 0});

  @override
  ConsumerState<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends ConsumerState<TopicScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _tabs = [
    ('🎬 Video', 0),
    ('📖 Ma\'ruza', 1),
    ('📝 Test', 2),
    ('🗂 Glossariy', 3),
    ('🧩 Krossvord', 4),
    ('🛠 Amaliyot', 5),
    ('📚 Resurs', 6),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(
        length: _tabs.length, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    return Scaffold(
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (topics) {
          final topic =
              topics.firstWhere((t) => t.id == widget.topicId);
          return Column(
            children: [
              _Header(topic: topic),
              _StageTabs(controller: _tab, tabs: _tabs),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    VideoStage(topic: topic),
                    LessonStage(topic: topic),
                    TestStage(topic: topic),
                    GlossaryStage(topic: topic),
                    CrosswordStage(topic: topic),
                    PracticalStage(topic: topic),
                    ResourceStage(topic: topic),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Topic topic;
  const _Header({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, MediaQuery.of(context).padding.top + 6, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A2B), Color(0xFF23284A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBtn(context, Icons.arrow_back_ios_new_rounded,
                  () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              const Text('Mavzuga qaytish',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${topic.order}-mavzu. ${topic.title}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.2)),
          const SizedBox(height: 4),
          Text('Motivatsiya → o‘zlashtirish → mustahkamlash → baholash',
              style: TextStyle(
                  color: Colors.white.withValues(alpha:0.6),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _StageTabs extends StatelessWidget {
  final TabController controller;
  final List<(String, int)> tabs;
  const _StageTabs({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surfaceColor,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: context.lineColor,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: context.mutedColor,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        tabs: tabs.map((t) => Tab(text: t.$1)).toList(),
      ),
    );
  }
}
