import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

String _mimeType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'pptx':
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}

Future<void> _triggerDownload(String assetPath, String fileName) async {
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: _mimeType(fileName)),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..setAttribute('download', fileName)
    ..click();
  web.URL.revokeObjectURL(url);
  anchor.remove();
}

Future<void> downloadAsset(
    BuildContext context, String assetPath, String fileName) async {
  await _triggerDownload(assetPath, fileName);
}

Future<void> openAsset(
    BuildContext context, String assetPath, String fileName) async {
  // Browsers cannot render Office files natively — trigger download so the OS
  // opens the file with the correct application (Word, PowerPoint, etc.).
  await _triggerDownload(assetPath, fileName);
}
