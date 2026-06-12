import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'youtube_local_server.dart';

/// Mobil/desktop (dart:io) uchun video pleyer.
///
/// Pleyerni lokal HTTP server ([YoutubeLocalServer]) orqali haqiqiy
/// `http://127.0.0.1:PORT` origin'idan yuklaydi — shu sabab YouTube embed
/// "Video unavailable (152/153)" bermaydi.
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
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final port = await YoutubeLocalServer.instance.ensureStarted();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel(
        'Progress',
        onMessageReceived: (msg) {
          final percent = double.tryParse(msg.message);
          if (percent != null) widget.onProgress(percent);
        },
      )
      ..loadRequest(
        Uri.parse(
          'http://127.0.0.1:$port/?v=${Uri.encodeComponent(widget.videoId)}',
        ),
      );
    if (mounted) setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: controller == null
          ? const ColoredBox(
              color: Color(0xFF000000),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : WebViewWidget(controller: controller),
    );
  }
}
