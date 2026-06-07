// lib/features/topic/stages/docx_parser.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

sealed class DocxBlock {}

class HeadingBlock extends DocxBlock {
  final int level;
  final String text;
  HeadingBlock({required this.level, required this.text});
}

class TextRun {
  final String text;
  final bool bold;
  final bool italic;
  const TextRun({required this.text, this.bold = false, this.italic = false});
}

class ParagraphBlock extends DocxBlock {
  final List<TextRun> runs;
  ParagraphBlock({required this.runs});
}

class ListItemBlock extends DocxBlock {
  final String text;
  final int level;
  ListItemBlock({required this.text, required this.level});
}

class DocxParser {
  /// Parses raw DOCX bytes (ZIP). Returns [] on any error.
  static List<DocxBlock> parse(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file == null) return [];
      final xmlStr = utf8.decode(file.content as List<int>);
      return parseXml(xmlStr);
    } catch (_) {
      return [];
    }
  }

  /// Parses the content of word/document.xml. Public for unit testing.
  static List<DocxBlock> parseXml(String xml) {
    try {
      final doc = XmlDocument.parse(xml);
      final body = doc.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.localName == 'body');

      final blocks = <DocxBlock>[];
      for (final para in body.childElements.where((e) => e.localName == 'p')) {
        final block = _parseParagraph(para);
        if (block != null) blocks.add(block);
      }
      return blocks;
    } catch (_) {
      return [];
    }
  }

  static DocxBlock? _parseParagraph(XmlElement p) {
    final pPr = _child(p, 'pPr');
    final styleVal = _attr(_child(pPr, 'pStyle'), 'val') ?? '';
    final numPr = _child(pPr, 'numPr');

    final runs = p.childElements
        .where((e) => e.localName == 'r')
        .map(_parseRun)
        .where((r) => r.text.isNotEmpty)
        .toList();

    if (runs.isEmpty) return null;

    final fullText = runs.map((r) => r.text).join();

    if (_isHeading(styleVal)) {
      return HeadingBlock(level: _headingLevel(styleVal), text: fullText);
    }
    if (numPr != null) {
      final ilvlVal = _attr(_child(numPr, 'ilvl'), 'val') ?? '0';
      return ListItemBlock(text: fullText, level: int.tryParse(ilvlVal) ?? 0);
    }
    return ParagraphBlock(runs: runs);
  }

  static TextRun _parseRun(XmlElement r) {
    final rPr = _child(r, 'rPr');
    final bold = rPr != null && rPr.childElements.any((e) => e.localName == 'b');
    final italic = rPr != null && rPr.childElements.any((e) => e.localName == 'i');
    final t = _child(r, 't');
    final text = t?.innerText ?? '';
    return TextRun(text: text, bold: bold, italic: italic);
  }

  static bool _isHeading(String val) {
    if (val.isEmpty) return false;
    if (RegExp(r'^[1-6]$').hasMatch(val)) return true;
    if (RegExp(r'heading\s*[1-6]', caseSensitive: false).hasMatch(val)) return true;
    return false;
  }

  static int _headingLevel(String val) {
    final m = RegExp(r'[1-6]').firstMatch(val);
    return int.tryParse(m?.group(0) ?? '1') ?? 1;
  }

  static XmlElement? _child(XmlElement? el, String localName) {
    if (el == null) return null;
    for (final c in el.childElements) {
      if (c.localName == localName) return c;
    }
    return null;
  }

  static String? _attr(XmlElement? el, String localName) {
    if (el == null) return null;
    for (final a in el.attributes) {
      if (a.localName == localName) return a.value;
    }
    return null;
  }
}
