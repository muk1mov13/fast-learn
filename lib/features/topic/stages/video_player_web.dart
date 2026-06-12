import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Web uchun video pleyer — youtube_player_iframe (haqiqiy `<iframe>`).
///
/// Web'da sahifaning o'z origin'i (masalan http://localhost yoki real domen)
/// ishlatilgani uchun YouTube embed muammosiz ishlaydi.
class TopicVideoPlayer extends StatefulWidget {
  final String videoId;
  final ValueChanged<double> onProgress;

  const TopicVideoPlayer({
    super.key,
    required this.videoId,
    required this.onProgress,
  });

  @override
  State<TopicVideoPlayer> createState() => _TopicVideoPlayerState();
}

class _TopicVideoPlayerState extends State<TopicVideoPlayer> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubeVideoState>? _sub;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableCaption: false,
      ),
    );
    _sub = _controller.videoStateStream.listen((state) {
      final dur = _controller.metadata.duration.inMilliseconds;
      if (dur <= 0) return;
      widget.onProgress(state.position.inMilliseconds / dur);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller, aspectRatio: 16 / 9);
  }
}
