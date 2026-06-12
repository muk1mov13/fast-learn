import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/providers.dart';
import '../../../widgets/common.dart';

class TestStage extends ConsumerStatefulWidget {
  final Topic topic;
  const TestStage({super.key, required this.topic});

  @override
  ConsumerState<TestStage> createState() => _TestStageState();
}

class _TestStageState extends ConsumerState<TestStage> {
  final Map<int, int> _answers = {};
  bool _submitted = false;
  int _scorePct = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    // Restore result from saved progress so it persists across tab switches.
    final test = widget.topic.test;
    if (test.isEmpty) return;
    final tp = ref.read(progressProvider).topics[widget.topic.id];
    if (tp != null && (tp.testScorePct > 0 || tp.test)) {
      _submitted = true;
      _scorePct = tp.testScorePct;
      _correct = (tp.testScorePct / 100 * test.length).round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.topic.test;
    if (test.isEmpty) {
      return _NoTest(topic: widget.topic);
    }
    if (_submitted) {
      return _ResultView(
        scorePct: _scorePct,
        correct: _correct,
        total: test.length,
        onRetry: () => setState(() {
          _answers.clear();
          _submitted = false;
        }),
      );
    }

    final allAnswered = _answers.length == test.length;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(
            text: 'Test savollari', color: AppColors.stageAssess),
        const SizedBox(height: 14),
        Text('Yakuniy test',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${test.length} ta savol · o\'tish chegarasi 60%',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        ...List.generate(test.length, (qi) => _question(context, qi, test[qi])),
        const SizedBox(height: 6),
        GradientButton(
          label: 'Testni yakunlash',
          enabled: allAnswered,
          gradient: const LinearGradient(
              colors: [AppColors.stageAssess, Color(0xFF8366F0)]),
          onPressed: allAnswered ? () => _submit(test) : null,
        ),
        const SizedBox(height: 10),
        if (!allAnswered)
          Center(
            child: Text(
                'Yakunlash uchun barcha savollarga javob bering '
                '(${_answers.length}/${test.length})',
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget _question(BuildContext context, int qi, TestQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.lineColor),
        boxShadow: AppShadow.soft(context.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SAVOL ${qi + 1}/${widget.topic.test.length}',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11)),
          const SizedBox(height: 6),
          Text(q.question,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(q.options.length, (oi) {
            return _option(context, qi, oi, q);
          }),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, int qi, int oi, TestQuestion q) {
    final selected = _answers[qi] == oi;
    Color border = context.lineColor;
    Color fill = context.surfaceColor;
    Color keyBg = context.softFillColor;
    Color keyFg = context.inkColor;

    if (!_submitted && selected) {
      border = AppColors.primary;
      fill = AppColors.primary.withValues(alpha: 0.08);
      keyBg = AppColors.primary;
      keyFg = Colors.white;
    }
    if (_submitted) {
      if (oi == q.correctIndex) {
        border = AppColors.ok;
        fill = AppColors.ok.withValues(alpha: 0.10);
        keyBg = AppColors.ok;
        keyFg = Colors.white;
      } else if (selected) {
        border = AppColors.danger;
        fill = AppColors.danger.withValues(alpha: 0.10);
        keyBg = AppColors.danger;
        keyFg = Colors.white;
      }
    }

    return GestureDetector(
      onTap: _submitted
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _answers[qi] = oi);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: keyBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('ABCD'[oi],
                  style: TextStyle(
                      color: keyFg,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(q.options[oi],
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.inkColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(List<TestQuestion> test) {
    HapticFeedback.mediumImpact();
    var correct = 0;
    for (var i = 0; i < test.length; i++) {
      if (_answers[i] == test[i].correctIndex) correct++;
    }
    final pct = ref
        .read(progressProvider.notifier)
        .submitTest(widget.topic.id, correct, test.length);
    setState(() {
      _submitted = true;
      _correct = correct;
      _scorePct = pct;
    });
  }
}

class _ResultView extends StatelessWidget {
  final int scorePct;
  final int correct;
  final int total;
  final VoidCallback onRetry;
  const _ResultView({
    required this.scorePct,
    required this.correct,
    required this.total,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final passed = scorePct >= 60;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 10),
        Center(
          child: ProgressRing(
            percent: scorePct / 100,
            size: 140,
            stroke: 12,
            color: passed ? AppColors.ok : AppColors.danger,
            trackColor: context.softFillColor,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$scorePct%',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w800)),
                Text('$correct / $total',
                    style: TextStyle(
                        color: context.mutedColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ),
        )
            .animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(),
        const SizedBox(height: 24),
        Center(
          child: Text(
            passed ? '🎉 Tabriklaymiz!' : 'Yana harakat qiling',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            passed
                ? 'Mavzu yakunlandi. Keyingi mavzu ochildi va ball qo\'shildi.'
                : 'Natija 60% dan past. Materialni takrorlab, qayta urinib ko\'ring.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 24),
        if (passed) ...[
          GradientButton(
            label: 'Mavzularga qaytish',
            gradient: const LinearGradient(
                colors: [AppColors.ok, Color(0xFF13935A)]),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Qayta yechish'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: passed ? AppColors.ok : AppColors.stageAssess,
              width: 1.5,
            ),
            foregroundColor: passed ? AppColors.ok : AppColors.stageAssess,
          ),
        ),
      ],
    );
  }
}

class _NoTest extends StatelessWidget {
  final Topic topic;
  const _NoTest({required this.topic});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 52, color: context.mutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text('Test tez orada',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Bu mavzu uchun variantli test hozircha kiritilmagan. '
              'topic_${topic.id}.json faylidagi "test" ro\'yxatiga savollar '
              'qo\'shsangiz, baholash avtomatik ishlaydi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
