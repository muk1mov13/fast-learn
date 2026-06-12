import 'dart:io';

/// Telefonda YouTube IFrame pleyerini **haqiqiy `http://127.0.0.1:PORT` origin**'idan
/// beradigan kichik lokal HTTP server.
///
/// Sabab: youtube_player_iframe Android'da pleyerni `loadDataWithBaseURL` orqali
/// yuklaydi — bunda hujjat origin'i `null`/opaque bo'lib, YouTube referrer'ni
/// tasdiqlay olmaydi va "Video unavailable (Error 152/153)" beradi. Pleyerni
/// haqiqiy http origin'idan berganda (web'da ishlagani kabi) YouTube tasdiqlaydi.
///
/// Bitta server butun ilova uchun bir marta ishga tushadi.
class YoutubeLocalServer {
  YoutubeLocalServer._();
  static final YoutubeLocalServer instance = YoutubeLocalServer._();

  int? _port;

  /// Serverni ishga tushiradi (allaqachon ishlayotgan bo'lsa, portni qaytaradi).
  Future<int> ensureStarted() async {
    final existing = _port;
    if (existing != null) return existing;

    // listen() aktiv subscription server obyektini tirik ushlab turadi.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = server.port;

    server.listen((req) async {
      final res = req.response;
      res.headers.contentType = ContentType.html;
      res.headers.set('Cache-Control', 'no-store');
      res.write(_playerHtml);
      await res.close();
    });

    return _port!;
  }

  /// `?v=<videoId>` parametridan videoId'ni o'qib, YT IFrame pleyerini quradi.
  /// Ko'rilgan ulush (0..1) `Progress` JS-kanali orqali Dart tomonga yuboriladi.
  static const String _playerHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
<style>
  html, body { margin:0; height:100%; background:#000; overflow:hidden; }
  #player { position:absolute; inset:0; width:100%; height:100%; }
</style>
</head>
<body>
<div id="player"></div>
<script>
  var videoId = new URLSearchParams(window.location.search).get('v');
  var tag = document.createElement('script');
  tag.src = 'https://www.youtube.com/iframe_api';
  document.head.appendChild(tag);

  var player, timer;

  function onYouTubeIframeAPIReady() {
    player = new YT.Player('player', {
      width: '100%',
      height: '100%',
      videoId: videoId,
      playerVars: {
        autoplay: 0,
        playsinline: 1,
        rel: 0,
        modestbranding: 1,
        fs: 1,
        // Haqiqiy origin (http://127.0.0.1:PORT) — YouTube buni tasdiqlaydi.
        origin: window.location.origin
      },
      events: { onStateChange: onStateChange }
    });
  }

  function onStateChange(e) {
    // 1 = playing
    if (e.data === 1) {
      if (!timer) timer = setInterval(report, 500);
    } else {
      report();
      if (e.data !== 1) { clearInterval(timer); timer = null; }
    }
  }

  function report() {
    try {
      var d = player.getDuration();
      var t = player.getCurrentTime();
      if (d > 0 && window.Progress) {
        Progress.postMessage(String(t / d));
      }
    } catch (err) {}
  }
</script>
</body>
</html>''';
}
