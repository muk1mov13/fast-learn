import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);
    final progress = ref.watch(progressProvider);

    return Scaffold(
      body: topicsAsync.when(
        loading: () => const _HomeSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Kontentni yuklashda xatolik:\n$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.mutedColor)),
          ),
        ),
        data: (topics) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(progress: progress)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Mavzular',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 11),
                itemBuilder: (context, i) {
                  final t = topics[i];
                  return _TopicCard(
                    topic: t,
                    progress: progress,
                  )
                      .animate()
                      .fadeIn(delay: (60 * i).ms, duration: 350.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOutCubic);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ProgressState progress;
  const _Hero({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = progress.overallPercent;
    return Container(
      padding: EdgeInsets.fromLTRB(
          22, MediaQuery.of(context).padding.top + 16, 22, 64),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assalomu alaykum',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Bilim sayohati',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              ProgressRing(
                percent: pct / 100,
                size: 62,
                stroke: 6,
                center: Text('$pct%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat('${progress.completedTopics}/${progress.topicCount}',
                  'Mavzu'),
              const SizedBox(width: 10),
              _stat('${progress.points}', 'Ball'),
              const SizedBox(width: 10),
              _stat('${progress.streak}', 'Kun 🔥'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final ProgressState progress;
  const _TopicCard({required this.topic, required this.progress});

  @override
  Widget build(BuildContext context) {
    final tp = progress.progressFor(topic.id);
    final unlocked = progress.isUnlocked(topic.id);
    final done = tp.isCompleted;
    final pct = tp.percent;

    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: AppCard(
        onTap: () {
          if (!unlocked) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                  content: Text('🔒 Avval oldingi mavzuni yakunlang'),
                  duration: Duration(seconds: 2)));
            return;
          }
          HapticFeedback.selectionClick();
          context.push('/topic/${topic.id}');
        },
        child: Row(
          children: [
            _badge(done, unlocked, topic.order),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _bar(context, pct / 100),
                  const SizedBox(height: 5),
                  Text(
                    unlocked
                        ? '$pct% bajarildi'
                        : '🔒 Qulflangan',
                    style: TextStyle(
                        color: context.mutedColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.mutedColor.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool done, bool unlocked, int order) {
    final gradient = done
        ? const LinearGradient(colors: [AppColors.ok, Color(0xFF13935A)])
        : (unlocked
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1B51D6)])
            : null);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: gradient,
        color: unlocked ? null : const Color(0xFFCDD2DD),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
          : (unlocked
              ? Text('$order',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18))
              : const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 20)),
    );
  }

  Widget _bar(BuildContext context, double v) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: 6, color: context.softFillColor),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v.clamp(0, 1)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 6,
                decoration: const BoxDecoration(
                    gradient: AppColors.progressGradient),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 11),
            child: Container(
              height: 78,
              decoration: BoxDecoration(
                color: context.softFillColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white24),
          ),
        ),
      ],
    );
  }
}
