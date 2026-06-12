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

class ImageBlock extends DocxBlock {
  final Uint8List bytes;
  ImageBlock({required this.bytes});
}

class DocxParser {
  /// Parses raw DOCX bytes (ZIP). Returns [] on any error.
  static List<DocxBlock> parse(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final rels = _parseRels(archive);
      final file = archive.findFile('word/document.xml');
      if (file == null) return [];
      final xmlStr = utf8.decode(file.content as List<int>);
      return _parseXml(xmlStr, archive, rels);
    } catch (_) {
      return [];
    }
  }

  /// Parses word/_rels/document.xml.rels → {rId: 'media/imageN.png'}
  static Map<String, String> _parseRels(Archive archive) {
    final rels = <String, String>{};
    final relsFile = archive.findFile('word/_rels/document.xml.rels');
    if (relsFile == null) return rels;
    try {
      final xml = utf8.decode(relsFile.content as List<int>);
      final doc = XmlDocument.parse(xml);
      for (final el in doc.descendants.whereType<XmlElement>()) {
        if (el.localName == 'Relationship') {
          final id = el.getAttribute('Id');
          final target = el.getAttribute('Target');
          final type = el.getAttribute('Type') ?? '';
          if (id != null && target != null && type.contains('image')) {
            rels[id] = target;
          }
        }
      }
    } catch (_) {}
    return rels;
  }

  static List<DocxBlock> _parseXml(
      String xml, Archive archive, Map<String, String> rels) {
    try {
      final doc = XmlDocument.parse(xml);
      final body = doc.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.localName == 'body');

      final blocks = <DocxBlock>[];
      for (final para in body.childElements.where((e) => e.localName == 'p')) {
        final imgBlock = _extractImage(para, archive, rels);
        if (imgBlock != null) {
          blocks.add(imgBlock);
          continue;
        }
        final block = _parseParagraph(para);
        if (block != null) blocks.add(block);
      }
      return blocks;
    } catch (_) {
      return [];
    }
  }

  /// Looks for a <w:drawing> → <a:blip r:embed="rIdN"/> in the paragraph.
  static ImageBlock? _extractImage(
      XmlElement p, Archive archive, Map<String, String> rels) {
    // Find any blip descendant with an embed attribute
    for (final el in p.descendants.whereType<XmlElement>()) {
      if (el.localName == 'blip') {
        final rId = el.attributes
            .where((a) => a.localName == 'embed')
            .map((a) => a.value)
            .firstOrNull;
        if (rId == null) continue;
        final target = rels[rId];
        if (target == null) continue;
        // target is relative to word/ folder, e.g. "media/image1.png"
        final path = target.startsWith('..') ? target.replaceFirst('..', '') : 'word/$target';
        final imgFile = archive.findFile(path) ??
            archive.findFile('word/$target') ??
            archive.findFile(target);
        if (imgFile != null) {
          final imgBytes = Uint8List.fromList(imgFile.content as List<int>);
          return ImageBlock(bytes: imgBytes);
        }
      }
    }
    return null;
  }

  /// Parses the content of word/document.xml. Public for unit testing.
  static List<DocxBlock> parseXml(String xml) {
    return _parseXml(xml, Archive(), {});
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
    if (RegExp(r'heading\s*[1-6]', caseSensitive: false).hasMatch(val)) {
      return true;
    }
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
