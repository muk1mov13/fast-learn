import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../data/models/test_result.dart';
import '../../state/admin_providers.dart';
import '../../widgets/common.dart';
import 'widgets/admin_widgets.dart';

class AdminUserDetailScreen extends ConsumerWidget {
  final String uid;
  const AdminUserDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(uid));
    final resultsAsync = ref.watch(userResultsProvider(uid));

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(title: const Text('Foydalanuvchi')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Foydalanuvchi topilmadi'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeaderCard(user: user),
              const SizedBox(height: 18),
              Text('Mavzular bo\'yicha natijalar',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              resultsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Xatolik: $e'),
                data: (results) => _ResultsTable(results: results),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final AppUser user;
  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial =
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName.isEmpty ? 'Ismsiz' : user.fullName,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: TextStyle(
                            color: context.mutedColor, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text('Oxirgi faollik: ${relativeLastActive(user.lastActive)}',
                        style: TextStyle(
                            color: context.mutedColor, fontSize: 11.5)),
                  ],
                ),
              ),
              ProgressRing(
                percent: user.overallPercent / 100,
                size: 62,
                stroke: 7,
                color: user.overallPercent >= 90
                    ? AppColors.ok
                    : AppColors.primary,
                trackColor: context.softFillColor,
                center: Text('${user.overallPercent}%',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                  label: 'Tugatgan',
                  value: '${user.completedTopics}/8',
                  icon: Icons.task_alt_rounded),
              _MiniStat(
                  label: 'Ball',
                  value: '${user.totalPoints}',
                  icon: Icons.star_rounded),
              _MiniStat(
                label: 'Sertifikat',
                value: user.certificateEarned ? 'Bor' : 'Yo\'q',
                icon: Icons.workspace_premium_rounded,
                highlight: user.certificateEarned,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.accent : context.inkColor;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          Text(label,
              style: TextStyle(color: context.mutedColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  final List<TestResult> results;
  const _ResultsTable({required this.results});

  @override
  Widget build(BuildContext context) {
    final byTopic = {for (final r in results) r.topicId: r};
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        children: [
          for (var i = 1; i <= 8; i++) ...[
            if (i > 1) Divider(height: 1, color: context.lineColor),
            _ResultRow(topicId: i, result: byTopic[i]),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final int topicId;
  final TestResult? result;
  const _ResultRow({required this.topicId, required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final passed = r != null && r.scorePct >= 60;
    final color = r == null
        ? context.mutedColor
        : passed
            ? AppColors.ok
            : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text('$topicId',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$topicId-mavzu',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  r == null
                      ? 'Topshirilmagan'
                      : '${r.correct}/${r.total} to\'g\'ri · ${_date(r.date)}',
                  style:
                      TextStyle(color: context.mutedColor, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (r != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('${r.scorePct}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            )
          else
            Icon(Icons.remove_rounded, color: context.mutedColor, size: 18),
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
