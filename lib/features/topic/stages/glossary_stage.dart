import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../widgets/common.dart';

class GlossaryStage extends StatelessWidget {
  final Topic topic;
  const GlossaryStage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final terms = topic.glossary;
    if (terms.isEmpty) {
      return const _EmptyStage(text: 'Bu mavzu uchun glossariy mavjud emas.');
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(text: 'Glossariy', color: AppColors.stageLearn),
        const SizedBox(height: 14),
        Text('Glossariy — flashcard',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Kartani bosing. Jami ${terms.length} ta atama.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        for (int i = 0; i < terms.length; i++) ...[
          _Flashcard(
            key: ValueKey(i),
            term: terms[i].term,
            definition: terms[i].definition,
          ),
          if (i < terms.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _Flashcard extends StatefulWidget {
  final String term;
  final String definition;
  const _Flashcard({super.key, required this.term, required this.definition});

  @override
  State<_Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<_Flashcard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _curved =
      CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
  bool _front = true;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (_front) {
      _c.forward();
    } else {
      _c.reverse();
    }
    _front = !_front;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _curved,
        builder: (context, _) {
          final angle = _curved.value * math.pi;
          final scale = 1.0 - 0.07 * math.sin(_curved.value * math.pi);
          final isBack = angle > math.pi / 2;
          return Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle),
              child: isBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _back(context),
                    )
                  : _frontCard(context),
            ),
          );
        },
      ),
    );
  }

  Widget _frontCard(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1B51D6)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.card(false),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ATAMA',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Text(widget.term,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15)),
            ],
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: Text('bosing ↻',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _back(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.lineColor),
        boxShadow: AppShadow.card(context.isDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TA'RIF",
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Text(widget.definition,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStage extends StatelessWidget {
  final String text;
  const _EmptyStage({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 48, color: context.mutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.mutedColor)),
          ],
        ),
      ),
    );
  }
}
