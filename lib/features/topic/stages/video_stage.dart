import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../state/providers.dart';
import '../../../widgets/common.dart';

class VideoStage extends ConsumerStatefulWidget {
  final Topic topic;
  const VideoStage({super.key, required this.topic});

  @override
  ConsumerState<VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends ConsumerState<VideoStage> {
  VideoPlayerController? _vc;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _completed = false;
  double _watchPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _completed =
        ref.read(progressProvider).progressFor(widget.topic.id).video;
    final path = widget.topic.video.assetPath;
    if (path.isNotEmpty) _initVideo(path);
  }

  Future<void> _initVideo(String assetPath) async {
    final vc = VideoPlayerController.asset(assetPath);
    await vc.initialize();
    if (!mounted) {
      await vc.dispose();
      return;
    }
    _vc = vc;
    _chewieController = ChewieController(
      videoPlayerController: vc,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      aspectRatio: 16 / 9,
    );
    vc.addListener(_onProgress);
    setState(() => _initialized = true);
  }

  void _onProgress() {
    if (_completed) return;
    final vc = _vc;
    if (vc == null || !vc.value.isInitialized) return;
    final dur = vc.value.duration.inMilliseconds;
    final pos = vc.value.position.inMilliseconds;
    if (dur <= 0) return;

    final newPercent = pos / dur;

    if (newPercent >= 0.9) {
      _completed = true;
      ref
          .read(progressProvider.notifier)
          .completeStage(widget.topic.id, isVideo: true);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('🎬 Video yakunlandi! +10 ball'),
            duration: Duration(milliseconds: 1600),
          ));
      }
      return;
    }

    if (newPercent - _watchPercent >= 0.05) {
      setState(() => _watchPercent = newPercent);
    }
  }

  @override
  void dispose() {
    _vc?.removeListener(_onProgress);
    _chewieController?.dispose();
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = ref.watch(progressProvider).progressFor(widget.topic.id);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const StageTag(
            text: 'Bosqich 1 · Motivatsiya',
            color: AppColors.stageMotivation),
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
            color: AppColors.ok.withOpacity(0.10),
            child: Row(
              children: const [
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
            // Guard matters when video fails to load (e.g. web 404): _watchPercent
            // stays 0.0 and the button stays disabled. When video plays normally,
            // _onProgress auto-completes at 90% and replaces this branch with the
            // "completed" card before the button could be tapped.
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
          if (widget.topic.video.assetPath.isNotEmpty && _watchPercent > 0)
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
    if (widget.topic.video.assetPath.isEmpty) {
      return _placeholderPlayer();
    }
    if (!_initialized || _chewieController == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: const Color(0xFF1B2444),
          ),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Chewie(controller: _chewieController!),
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
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3), blurRadius: 20)
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: AppColors.primary, size: 40),
        ),
      ),
    );
  }
}
