import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../widgets/common.dart';
import 'crossword_solver.dart';
import 'docx_parser.dart';
import 'docx_file_actions.dart';

/// ---------- KROSSVORD ----------
class CrosswordStage extends StatefulWidget {
  final Topic topic;
  const CrosswordStage({super.key, required this.topic});

  @override
  State<CrosswordStage> createState() => _CrosswordStageState();
}

class _CrosswordStageState extends State<CrosswordStage>
    with SingleTickerProviderStateMixin {
  late final List<PlacedWord> _placed;
  late final Map<(int, int), List<int>> _cellWords;
  late final int _rows;
  late final int _cols;

  final _solved = <int>{};
  int? _selectedIdx;
  final _inputCtrl = TextEditingController();
  int _tabIdx = 0;

  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _shakeAnim = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 7.0, end: -7.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _placed = CrosswordSolver.solve(widget.topic.crossword);
    _buildCellMap();
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _shakeCtrl.reset();
    });
  }

  void _buildCellMap() {
    _cellWords = {};
    int maxRow = 0, maxCol = 0;
    for (int i = 0; i < _placed.length; i++) {
      for (final cell in _placed[i].cells.keys) {
        _cellWords.putIfAbsent(cell, () => []).add(i);
        if (cell.$1 > maxRow) maxRow = cell.$1;
        if (cell.$2 > maxCol) maxCol = cell.$2;
      }
    }
    _rows = maxRow + 1;
    _cols = maxCol + 1;
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _selectWord(int idx) => setState(() {
        _selectedIdx = idx;
        _inputCtrl.clear();
      });

  void _onCellTap(int row, int col) {
    final words = _cellWords[(row, col)];
    if (words == null || words.isEmpty) return;
    if (words.length == 1) {
      _selectWord(words[0]);
    } else {
      final cur = words.indexOf(_selectedIdx ?? -1);
      _selectWord(words[(cur + 1) % words.length]);
    }
  }

  void _checkAnswer() {
    final idx = _selectedIdx;
    if (idx == null) return;
    final typed = _inputCtrl.text.toUpperCase().replaceAll("'", '').replaceAll('‘', '').replaceAll('’', '');
    if (typed == _placed[idx].answer) {
      HapticFeedback.heavyImpact();
      setState(() {
        _solved.add(idx);
        _selectedIdx = null;
        _inputCtrl.clear();
      });
    } else {
      HapticFeedback.vibrate();
      _shakeCtrl.forward();
      setState(() => _inputCtrl.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_placed.isEmpty) {
      return const _Empty(text: 'Bu mavzu uchun krossvord mavjud emas.');
    }
    final allSolved = _solved.length == _placed.length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(text: 'Krossvord', color: AppColors.stageReinforce),
        const SizedBox(height: 14),
        Text('Krossvord', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Katakchaga yoki savolga bosib javob kiriting.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (allSolved) _CompletionBanner(count: _placed.length),
        _GridWidget(
          placed: _placed,
          cellWords: _cellWords,
          rows: _rows,
          cols: _cols,
          selectedIdx: _selectedIdx,
          solved: _solved,
          onCellTap: _onCellTap,
        ),
        const SizedBox(height: 12),
        if (_selectedIdx != null && !_solved.contains(_selectedIdx))
          _InputArea(
            word: _placed[_selectedIdx!],
            ctrl: _inputCtrl,
            shakeAnim: _shakeAnim,
            onCheck: _checkAnswer,
          ),
        const SizedBox(height: 12),
        _CluesSection(
          placed: _placed,
          solved: _solved,
          selectedIdx: _selectedIdx,
          tabIdx: _tabIdx,
          onTabChange: (i) => setState(() => _tabIdx = i),
          onTap: _selectWord,
        ),
      ],
    );
  }
}

class _GridWidget extends StatelessWidget {
  final List<PlacedWord> placed;
  final Map<(int, int), List<int>> cellWords;
  final int rows;
  final int cols;
  final int? selectedIdx;
  final Set<int> solved;
  final void Function(int, int) onCellTap;

  const _GridWidget({
    required this.placed,
    required this.cellWords,
    required this.rows,
    required this.cols,
    required this.selectedIdx,
    required this.solved,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedWordCells = selectedIdx != null
        ? placed[selectedIdx!].cells.keys.toSet()
        : const <(int, int)>{};

    final startNums = <(int, int), int>{};
    for (final w in placed) {
      startNums.putIfAbsent((w.row, w.col), () => w.number);
    }

    const cz = 28.0;
    const gp = 2.0;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.soft(context.isDark),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(rows, (r) {
            return Row(
              children: List.generate(cols, (c) {
                final wordIdxs = cellWords[(r, c)];
                final isBlack = wordIdxs == null || wordIdxs.isEmpty;

                if (isBlack) {
                  return const SizedBox(width: cz + gp, height: cz + gp);
                }

                final isSolved = wordIdxs.any((i) => solved.contains(i));
                final isHighlighted = selectedWordCells.contains((r, c));
                final num = startNums[(r, c)];

                String? displayLetter;
                if (isSolved) {
                  final si = wordIdxs.firstWhere((i) => solved.contains(i));
                  displayLetter = placed[si].cells[(r, c)];
                }

                Color bg;
                Color borderColor;
                double borderWidth;
                if (isSolved) {
                  bg = AppColors.ok.withValues(alpha: 0.12);
                  borderColor = AppColors.ok;
                  borderWidth = 1.5;
                } else if (isHighlighted) {
                  bg = AppColors.primary.withValues(alpha: 0.10);
                  borderColor = AppColors.primary;
                  borderWidth = 1.5;
                } else {
                  bg = context.surfaceColor;
                  borderColor = context.lineColor;
                  borderWidth = 1.0;
                }

                return GestureDetector(
                  onTap: () => onCellTap(r, c),
                  child: Container(
                    width: cz + gp,
                    height: cz + gp,
                    padding: const EdgeInsets.all(gp / 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: borderColor, width: borderWidth),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (num != null)
                            Positioned(
                              top: 1, left: 2,
                              child: Text(
                                '$num',
                                style: TextStyle(
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSolved ? AppColors.ok : AppColors.primary,
                                  height: 1,
                                ),
                              ),
                            ),
                          if (displayLetter != null)
                            Center(
                              child: Text(
                                displayLetter,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ok,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  final int count;
  const _CompletionBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.ok.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.ok.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.ok, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Krossvord yechildi!',
                  style: TextStyle(
                    color: AppColors.ok,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Barcha $count ta so'z to'g'ri topildi.",
                  style: TextStyle(
                    color: AppColors.ok.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final PlacedWord word;
  final TextEditingController ctrl;
  final Animation<double> shakeAnim;
  final VoidCallback onCheck;

  const _InputArea({
    required this.word,
    required this.ctrl,
    required this.shakeAnim,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final dir = word.isHorizontal ? '→ Gorizontal' : '↓ Vertikal';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(
              text: '${word.number}  $dir  ',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: '(${word.length} harf)',
              style: TextStyle(color: context.mutedColor, fontSize: 12),
            ),
          ])),
          const SizedBox(height: 4),
          Text(word.clue.clue,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: shakeAnim,
            builder: (context, child) =>
                Transform.translate(offset: Offset(shakeAnim.value, 0), child: child),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ValueListenableBuilder(
                    valueListenable: ctrl,
                    builder: (_, value, __) {
                      final typed = value.text.characters.toList();
                      return Row(
                        children: List.generate(word.length, (i) {
                          final has = i < typed.length;
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 28,
                            height: 32,
                            decoration: BoxDecoration(
                              color: has
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : context.surfaceColor,
                              border: Border.all(
                                color: has ? AppColors.primary : context.lineColor,
                                width: has ? 1.5 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              has ? typed[i].toUpperCase() : '_',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: has ? AppColors.primary : context.lineColor,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  maxLength: word.length,
                  textCapitalization: TextCapitalization.characters,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Javobni kiriting...',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: context.lineColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tekshirish',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CluesSection extends StatelessWidget {
  final List<PlacedWord> placed;
  final Set<int> solved;
  final int? selectedIdx;
  final int tabIdx;
  final void Function(int) onTabChange;
  final void Function(int) onTap;

  const _CluesSection({
    required this.placed,
    required this.solved,
    required this.selectedIdx,
    required this.tabIdx,
    required this.onTabChange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hWords = placed.asMap().entries.where((e) => e.value.isHorizontal).toList()
      ..sort((a, b) => a.value.number.compareTo(b.value.number));
    final vWords = placed.asMap().entries.where((e) => !e.value.isHorizontal).toList()
      ..sort((a, b) => a.value.number.compareTo(b.value.number));
    final current = tabIdx == 0 ? hWords : vWords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _TabChip(
            label: '→ Gorizontal (${hWords.length})',
            active: tabIdx == 0,
            onTap: () => onTabChange(0),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: '↓ Vertikal (${vWords.length})',
            active: tabIdx == 1,
            onTap: () => onTabChange(1),
          ),
        ]),
        const SizedBox(height: 8),
        ...current.map((entry) {
          final i = entry.key;
          final w = entry.value;
          final isDone = solved.contains(i);
          final isSel = selectedIdx == i;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(
              onTap: isDone ? null : () => onTap(i),
              child: Opacity(
                opacity: isDone ? 0.5 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(
                        text: '${w.number}. ',
                        style: TextStyle(
                          color: isSel ? AppColors.primary : context.mutedColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: '(${w.length} harf)  ',
                        style: TextStyle(
                          color: context.mutedColor,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: w.clue.clue,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ])),
                    if (isDone) ...[
                      const SizedBox(height: 4),
                      Text(
                        '→ ${w.answer}',
                        style: const TextStyle(
                          color: AppColors.ok,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.primary : context.lineColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : context.mutedColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// ---------- AMALIYOT ----------
class PracticalStage extends StatefulWidget {
  final Topic topic;
  const PracticalStage({super.key, required this.topic});

  @override
  State<PracticalStage> createState() => _PracticalStageState();
}

class _PracticalStageState extends State<PracticalStage> {
  late final Future<List<DocxBlock>> _docFuture;
  late final Future<bool> _topshiriqExists;

  @override
  void initState() {
    super.initState();
    _docFuture = _loadDocx(_amaliyotPath(widget.topic.id));
    _topshiriqExists = _checkAsset(_topshiriqPath(widget.topic.id));
  }

  String _amaliyotPath(int id) =>
      'assets/materials/topic_$id/amaliyot/${id}_amaliy.docx';

  String _topshiriqPath(int id) =>
      'assets/materials/topic_$id/amaliyot/${id}_topshiriq.docx';

  Future<List<DocxBlock>> _loadDocx(String path) async {
    try {
      final data = await rootBundle.load(path);
      return DocxParser.parse(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      return [];
    }
  }

  Future<bool> _checkAsset(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(text: 'Amaliyot', color: AppColors.stageReinforce),
        const SizedBox(height: 14),
        Text('Amaliy topshiriq',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 14),
        _DocxViewer(future: _docFuture),
        const SizedBox(height: 16),
        FutureBuilder<bool>(
          future: _topshiriqExists,
          builder: (context, snap) {
            if (snap.data != true) return const SizedBox.shrink();
            return _TopshiriqCard(
              path: _topshiriqPath(widget.topic.id),
              fileName: '${widget.topic.id}_topshiriq.docx',
            );
          },
        ),
      ],
    );
  }
}

class _DocxViewer extends StatelessWidget {
  final Future<List<DocxBlock>> future;
  const _DocxViewer({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocxBlock>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.data == null || snap.data!.isEmpty) {
          return AppCard(
            child: Row(
              children: [
                Icon(Icons.error_outline, color: context.mutedColor),
                const SizedBox(width: 8),
                Text('Hujjat yuklanmadi',
                    style: TextStyle(color: context.mutedColor)),
              ],
            ),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                snap.data!.map((b) => _buildBlock(context, b)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBlock(BuildContext context, DocxBlock block) {
    final theme = Theme.of(context);
    switch (block) {
      case HeadingBlock(:final level, :final text):
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            text,
            style: switch (level) {
              1 => theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
              2 => theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
              _ => theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            },
          ),
        );
      case ParagraphBlock(:final runs) when runs.isNotEmpty:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: runs
                  .map((r) => TextSpan(
                        text: r.text,
                        style: TextStyle(
                          fontWeight:
                              r.bold ? FontWeight.bold : FontWeight.normal,
                          fontStyle:
                              r.italic ? FontStyle.italic : FontStyle.normal,
                        ),
                      ))
                  .toList(),
            ),
          ),
        );
      case ListItemBlock(:final text, :final level):
        return Padding(
          padding: EdgeInsets.only(left: level * 16.0, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
      case ImageBlock(:final bytes):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TopshiriqCard extends StatelessWidget {
  final String path;
  final String fileName;
  const _TopshiriqCard({required this.path, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.description_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Topshiriq fayli',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      fileName,
                      style: TextStyle(
                          color: context.mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      downloadAsset(context, path, fileName),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Yuklab olish'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => openAsset(context, path, fileName),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Ochish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------- RESURS ----------
class ResourceStage extends StatelessWidget {
  final Topic topic;
  const ResourceStage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final resources = topic.resources;
    if (resources.isEmpty) {
      return const _Empty(text: 'Bu mavzu uchun resurslar tez orada qo\'shiladi.');
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(
            text: 'Resurslar', color: AppColors.stageReinforce),
        const SizedBox(height: 14),
        Text('Qo\'shimcha materiallar',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('O\'rganishni chuqurlashtirish uchun tavsiya etilgan resurslar.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        ...resources.map((r) => _ResourceCard(item: r)),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final ResourceItem item;
  const _ResourceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasFile = item.url.startsWith('assets/');
    final fileName = hasFile ? item.url.split('/').last : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_typeIcon(item.type),
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context).textTheme.titleSmall),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.description,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                      if (hasFile) ...[
                        const SizedBox(height: 4),
                        Text(fileName,
                            style: TextStyle(
                                color: context.mutedColor, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (hasFile) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          downloadAsset(context, item.url, fileName),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Yuklab olish'),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          openAsset(context, item.url, fileName),
                      icon:
                          const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ochish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'article':
        return Icons.article_outlined;
      default:
        return Icons.link_rounded;
    }
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
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
