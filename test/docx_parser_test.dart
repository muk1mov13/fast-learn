// test/docx_parser_test.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:texnik_ijodkorlik/features/topic/stages/docx_parser.dart';

Uint8List _makeDocx(String xmlContent) {
  final archive = Archive();
  final bytes = utf8.encode(xmlContent);
  archive.addFile(ArchiveFile('word/document.xml', bytes.length, bytes));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

const _ns = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"';

String _wrap(String body) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<w:document $_ns><w:body>$body</w:body></w:document>';

void main() {
  group('DocxParser.parseXml', () {
    test('returns HeadingBlock for pStyle val="1"', () {
      final xml = _wrap(
        '<w:p>'
        '<w:pPr><w:pStyle w:val="1"/></w:pPr>'
        '<w:r><w:t>Sarlavha</w:t></w:r>'
        '</w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      expect(blocks, hasLength(1));
      expect(blocks.first, isA<HeadingBlock>());
      final h = blocks.first as HeadingBlock;
      expect(h.level, 1);
      expect(h.text, 'Sarlavha');
    });

    test('returns HeadingBlock for pStyle val="Heading2"', () {
      final xml = _wrap(
        '<w:p>'
        '<w:pPr><w:pStyle w:val="Heading2"/></w:pPr>'
        '<w:r><w:t>H2</w:t></w:r>'
        '</w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      expect(blocks.first, isA<HeadingBlock>());
      expect((blocks.first as HeadingBlock).level, 2);
    });

    test('returns ParagraphBlock for plain paragraph', () {
      final xml = _wrap(
        '<w:p><w:r><w:t>Oddiy matn</w:t></w:r></w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      expect(blocks, hasLength(1));
      expect(blocks.first, isA<ParagraphBlock>());
      final p = blocks.first as ParagraphBlock;
      expect(p.runs.first.text, 'Oddiy matn');
      expect(p.runs.first.bold, false);
      expect(p.runs.first.italic, false);
    });

    test('detects bold run', () {
      final xml = _wrap(
        '<w:p>'
        '<w:r><w:rPr><w:b/></w:rPr><w:t>Qalin</w:t></w:r>'
        '</w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      final p = blocks.first as ParagraphBlock;
      expect(p.runs.first.bold, true);
      expect(p.runs.first.italic, false);
    });

    test('detects italic run', () {
      final xml = _wrap(
        '<w:p>'
        '<w:r><w:rPr><w:i/></w:rPr><w:t>Kursiv</w:t></w:r>'
        '</w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      final p = blocks.first as ParagraphBlock;
      expect(p.runs.first.italic, true);
      expect(p.runs.first.bold, false);
    });

    test('detects list item', () {
      final xml = _wrap(
        '<w:p>'
        '<w:pPr><w:numPr>'
        '<w:ilvl w:val="0"/><w:numId w:val="1"/>'
        '</w:numPr></w:pPr>'
        '<w:r><w:t>Element</w:t></w:r>'
        '</w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      expect(blocks.first, isA<ListItemBlock>());
      final li = blocks.first as ListItemBlock;
      expect(li.text, 'Element');
      expect(li.level, 0);
    });

    test('list item level from ilvl', () {
      final xml = _wrap(
        '<w:p>'
        '<w:pPr><w:numPr>'
        '<w:ilvl w:val="2"/><w:numId w:val="1"/>'
        '</w:numPr></w:pPr>'
        '<w:r><w:t>Nested</w:t></w:r>'
        '</w:p>',
      );
      final blocks = DocxParser.parseXml(xml);
      expect((blocks.first as ListItemBlock).level, 2);
    });

    test('skips empty paragraphs', () {
      final xml = _wrap('<w:p/>');
      expect(DocxParser.parseXml(xml), isEmpty);
    });

    test('skips paragraphs with only empty text runs', () {
      final xml = _wrap('<w:p><w:r><w:t></w:t></w:r></w:p>');
      expect(DocxParser.parseXml(xml), isEmpty);
    });

    test('concatenates multiple runs for heading text', () {
      final xml = _wrap(
        '<w:p>'
        '<w:pPr><w:pStyle w:val="1"/></w:pPr>'
        '<w:r><w:t>Bir </w:t></w:r>'
        '<w:r><w:t>ikki</w:t></w:r>'
        '</w:p>',
      );
      final h = DocxParser.parseXml(xml).first as HeadingBlock;
      expect(h.text, 'Bir ikki');
    });

    test('returns empty list for invalid XML', () {
      expect(DocxParser.parseXml('not xml {{{{'), isEmpty);
    });
  });

  group('DocxParser.parse', () {
    test('extracts paragraph from valid DOCX bytes', () {
      final xml = _wrap('<w:p><w:r><w:t>Salom</w:t></w:r></w:p>');
      final bytes = _makeDocx(xml);
      final blocks = DocxParser.parse(bytes);
      expect(blocks, hasLength(1));
      expect((blocks.first as ParagraphBlock).runs.first.text, 'Salom');
    });

    test('returns empty for invalid bytes', () {
      expect(DocxParser.parse(Uint8List.fromList([1, 2, 3])), isEmpty);
    });
  });
}
