import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'certificate_card.dart';

String _formatDate() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final topicsAsync = ref.watch(topicsProvider);
    final pct = progress.overallPercent;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text('Mening natijalarim',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  ProgressRing(
                    percent: pct / 100,
                    size: 84,
                    stroke: 8,
                    center: Text('$pct%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Umumiy o‘zlashtirish',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                            '${progress.completedTopics}/${progress.topicCount} mavzu yakunlandi',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('${progress.points} ball · ${progress.streak} kun streak',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (progress.hasCertificate) ...[
              _CertificateCard(progress: progress),
              const SizedBox(height: 20),
            ],
            Text('Nishonlar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _Badges(earned: progress.badges),
            const SizedBox(height: 20),
            Text('Mavzular bo‘yicha',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            topicsAsync.maybeWhen(
              data: (topics) => Column(
                children: topics.map((t) {
                  final p = progress.progressFor(t.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${t.order}-mavzu',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                              Text('${p.percent}%',
                                  style: TextStyle(
                                      color: context.mutedColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(
                                    height: 6, color: context.softFillColor),
                                FractionallySizedBox(
                                  widthFactor: (p.percent / 100).clamp(0, 1),
                                  child: Container(
                                    height: 6,
                                    decoration: const BoxDecoration(
                                        gradient:
                                            AppColors.progressGradient),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final ProgressState progress;
  const _CertificateCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.ok, Color(0xFF13935A)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_membership_rounded,
                    color: Color(0xFFF4C66B), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sertifikat olindi!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Tabriklaymiz! Barcha 8 mavzu yakunlandi va '
              'umumiy o\'zlashtirish 90% dan yuqori.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Sertifikatni ko\'rish',
            gradient: const LinearGradient(
                colors: [AppColors.ok, Color(0xFF13935A)]),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _CertificateView(progress: progress),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateView extends ConsumerStatefulWidget {
  final ProgressState progress;
  const _CertificateView({required this.progress});

  @override
  ConsumerState<_CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends ConsumerState<_CertificateView> {
  final GlobalKey _certKey = GlobalKey();
  bool _exporting = false;

  void _showNameDialog() {
    final controller =
        TextEditingController(text: ref.read(progressProvider).studentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ismingizni kiriting'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Familiya Ism',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _saveName(ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor'),
          ),
          FilledButton(
            onPressed: () => _saveName(ctx, controller.text),
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  void _saveName(BuildContext ctx, String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      ref.read(progressProvider.notifier).setStudentName(trimmed);
    }
    Navigator.pop(ctx);
  }

  Future<void> _downloadPdf() async {
    if (_exporting) return;

    final name = ref.read(progressProvider).studentName.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avval ismingizni kiriting.'),
        ),
      );
      _showNameDialog();
      return;
    }

    setState(() => _exporting = true);
    try {
      // RepaintBoundary'ni yuqori sifatda rasmga aylantirish
      final boundary = _certKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // PNG'ni A4 landshaft PDF sahifasiga joylashtirish
      final doc = pw.Document();
      final memImage = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) => pw.Center(
            child: pw.Image(memImage, fit: pw.BoxFit.contain),
          ),
        ),
      );

      final safeName = name.replaceAll(RegExp(r'[^\w]+'), '_');
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'sertifikat_$safeName.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yuklab olishda xatolik: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final hasName = progress.studentName.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sertifikat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Ismni tahrirlash',
            onPressed: _showNameDialog,
          ),
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'PDF yuklab olish',
            onPressed: _exporting ? null : _downloadPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!hasName)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: const Color(0xFFFFCC02)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sertifikatingizda ismingizni ko\'rsatish uchun kiriting.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF5D4037)),
                      ),
                    ),
                    TextButton(
                      onPressed: _showNameDialog,
                      child: const Text('Kiriting'),
                    ),
                  ],
                ),
              ),
            RepaintBoundary(
              key: _certKey,
              child: CertificateCard(
                studentName: progress.studentName,
                dateText: _formatDate(),
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: _exporting ? 'Tayyorlanmoqda...' : 'PDF yuklab olish',
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              onPressed: _exporting ? null : _downloadPdf,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  final Set<String> earned;
  const _Badges({required this.earned});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(kAllBadges.length, (i) {
        final b = kAllBadges[i];
        final on = earned.contains(b.key);
        return Container(
          width: (MediaQuery.of(context).size.width - 36 - 20) / 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.lineColor),
          ),
          child: Opacity(
            opacity: on ? 1 : 0.45,
            child: Row(
              children: [
                Icon(b.icon,
                    color: on ? AppColors.accent : context.mutedColor,
                    size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(b.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 11.5)),
                ),
              ],
            ),
          ),
        )
            .animate(target: on ? 1 : 0)
            .scaleXY(begin: 1, end: 1.04, duration: 250.ms)
            .then()
            .scaleXY(begin: 1.04, end: 1);
      }),
    );
  }
}
