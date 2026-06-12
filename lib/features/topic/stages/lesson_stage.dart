import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/providers.dart';
import '../../../widgets/common.dart';

class LessonStage extends ConsumerWidget {
  final Topic topic;
  const LessonStage({super.key, required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tp = ref.watch(progressProvider).progressFor(topic.id);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(
            text: "Ma'ruza", color: AppColors.stageLearn),
        const SizedBox(height: 14),
        Text(topic.lesson.title,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (topic.lesson.slideTitles.isNotEmpty) ...[
          Text('Reja / slaydlar',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topic.lesson.slideTitles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, i) => Container(
                width: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9EEFB), Color(0xFFDBE4FB)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.bottomLeft,
                child: Text('${i + 1} · ${topic.lesson.slideTitles[i]}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5)),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        _LessonBody(topic: topic),
        if (topic.questions.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Maruzaga doir savollar',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...List.generate(topic.questions.length, (i) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  border: Border(
                    left: const BorderSide(color: AppColors.accent, width: 3),
                    top: BorderSide(color: context.lineColor),
                    right: BorderSide(color: context.lineColor),
                    bottom: BorderSide(color: context.lineColor),
                  ),
                ),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '${i + 1}. ',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: topic.questions[i]),
                ]), style: Theme.of(context).textTheme.bodyMedium),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
        const SizedBox(height: 22),
        if (tp.lesson)
          AppCard(
            color: AppColors.ok.withValues(alpha: 0.10),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.ok),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Dars yakunlangan',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.ok))),
              ],
            ),
          )
        else
          GradientButton(
            label: 'Darsni yakunlash (+10 ball)',
            gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1B51D6)]),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref
                  .read(progressProvider.notifier)
                  .completeStage(topic.id, isVideo: false);
            },
          ),
      ],
    );
  }
}

/// Matn ichida glossariy atamalari aniqlanib, bosilganda ta'rif chiqadi.
class _LessonBody extends StatelessWidget {
  final Topic topic;
  const _LessonBody({required this.topic});

  @override
  Widget build(BuildContext context) {
    final body = _stripMarkdown(topic.lesson.bodyMarkdown);
    final terms = {for (final g in topic.glossary) g.term: g.definition};
    final spans = _buildSpans(context, body, terms);
    return Text.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  static String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*', dotAll: true), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*', dotAll: true), r'$1')
        .replaceAll(RegExp(r'^#{1,6} +', multiLine: true), '');
  }

  List<InlineSpan> _buildSpans(
      BuildContext context, String text, Map<String, String> terms) {
    if (terms.isEmpty) return [TextSpan(text: text)];
    // Atamalarni uzunligi bo'yicha kamayuvchi tartibda (uzunroq mos kelsin).
    final keys = terms.keys.where((k) => k.trim().isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final spans = <InlineSpan>[];
    var rest = text;

    while (rest.isNotEmpty) {
      int matchIdx = -1;
      String matched = '';
      for (final k in keys) {
        final idx = rest.toLowerCase().indexOf(k.toLowerCase());
        if (idx != -1 && (matchIdx == -1 || idx < matchIdx)) {
          matchIdx = idx;
          matched = k;
        }
      }
      if (matchIdx == -1) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (matchIdx > 0) {
        spans.add(TextSpan(text: rest.substring(0, matchIdx)));
      }
      final actual = rest.substring(matchIdx, matchIdx + matched.length);
      spans.add(TextSpan(
        text: actual,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _showTerm(context, matched, terms[matched] ?? ''),
      ));
      rest = rest.substring(matchIdx + matched.length);
    }
    return spans;
  }

  void _showTerm(BuildContext context, String term, String def) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StageTag(text: 'Atama', color: AppColors.accent),
            const SizedBox(height: 12),
            Text(term, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(def, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
