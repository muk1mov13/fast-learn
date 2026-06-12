import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/providers.dart';
import '../../../widgets/common.dart';
// Platforma bo'yicha pleyer: web → youtube_player_iframe, mobil → lokal
// server + webview_flutter (haqiqiy http://127.0.0.1 origin).
import 'video_player_web.dart'
    if (dart.library.io) 'video_player_io.dart';

class VideoStage extends ConsumerStatefulWidget {
  final Topic topic;
  const VideoStage({super.key, required this.topic});

  @override
  ConsumerState<VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends ConsumerState<VideoStage> {
  bool _completed = false;
  double _watchPercent = 0.0;

  bool get _hasVideo => widget.topic.video.youtubeId.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _completed =
        ref.read(progressProvider).progressFor(widget.topic.id).video;
  }

  @override
  void didUpdateWidget(covariant VideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mavzu o'zgarsa, holatni yangi mavzu uchun qayta o'qiymiz. Pleyer widget'i
    // o'zining ValueKey(videoId)'si orqali to'liq qayta quriladi.
    if (oldWidget.topic.id != widget.topic.id) {
      _completed =
          ref.read(progressProvider).progressFor(widget.topic.id).video;
      _watchPercent = 0.0;
    }
  }

  /// Pleyerdan kelgan ko'rilgan ulush (0..1). 90% da bosqichni yakunlaydi.
  void _onProgress(double percent) {
    if (_completed || !mounted) return;

    if (percent >= 0.9) {
      _completed = true;
      ref
          .read(progressProvider.notifier)
          .completeStage(widget.topic.id, isVideo: true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('🎬 Video yakunlandi! +10 ball'),
          duration: Duration(milliseconds: 1600),
        ));
      setState(() => _watchPercent = 1.0);
      return;
    }

    if (percent - _watchPercent >= 0.05) {
      setState(() => _watchPercent = percent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = ref.watch(progressProvider).progressFor(widget.topic.id);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(text: 'Video', color: AppColors.stageMotivation),
        const SizedBox(height: 14),
        _buildPlayer(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.topic.video.title,
              style: TextStyle(
                  color: context.mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            if (widget.topic.video.duration.isNotEmpty)
              Text(
                widget.topic.video.duration,
                style: TextStyle(
                    color: context.mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Videoda mavzuning real hayotdagi qo\'llanilishi ko\'rsatiladi. '
          'Video 90% ko\'rilganda avtomatik yakunlanadi.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        if (tp.video)
          AppCard(
            color: AppColors.ok.withValues(alpha: 0.10),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.ok),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu bosqich yakunlangan',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.ok),
                  ),
                ),
              ],
            ),
          )
        else ...[
          GradientButton(
            label: 'Videoni yakunlash (+10 ball)',
            gradient: const LinearGradient(
                colors: [AppColors.stageMotivation, Color(0xFFFF9234)]),
            // Video 90% ko'rilmaguncha tugma o'chiq turadi. Odatda pleyer
            // 90% da avtomatik yakunlaydi; bu tugma zaxira (qo'lda) variant.
            onPressed: _watchPercent >= 0.9
                ? () {
                    HapticFeedback.mediumImpact();
                    _completed = true;
                    ref
                        .read(progressProvider.notifier)
                        .completeStage(widget.topic.id, isVideo: true);
                  }
                : null,
          ),
          if (_hasVideo && _watchPercent > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Video ${(_watchPercent * 100).round()}% ko'rildi",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: context.mutedColor),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPlayer() {
    if (!_hasVideo) return _placeholderPlayer();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      // Key youtubeId'ga bog'langan: mavzu o'zgarganda pleyer to'liq qayta
      // quriladi (eski video qolib ketmaydi).
      child: TopicVideoPlayer(
        key: ValueKey(widget.topic.video.youtubeId),
        videoId: widget.topic.video.youtubeId.trim(),
        onProgress: _onProgress,
      ),
    );
  }

  Widget _placeholderPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2444), Color(0xFF10193A)],
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: AppColors.primary, size: 40),
        ),
      ),
    );
  }
}
