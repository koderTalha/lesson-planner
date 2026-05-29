import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;

import '../models/lesson_plan_generated.dart';
import '../models/lesson_plan_input.dart';

String _ensureNumberedLessonObjectives(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');
  final swbatIdx =
      lines.indexWhere((l) => l.toUpperCase().contains('SWBAT'));
  if (swbatIdx == -1) {
    return _numberPlainObjectiveLines(lines);
  }
  final out = <String>[];
  for (var i = 0; i <= swbatIdx; i++) {
    out.add(lines[i]);
  }
  var n = 1;
  for (var i = swbatIdx + 1; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      out.add(line);
      continue;
    }
    if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
      out.add(line);
      final m = RegExp(r'^(\d+)\.').firstMatch(trimmed);
      if (m != null) {
        n = int.parse(m.group(1)!) + 1;
      }
      continue;
    }
    var body = trimmed;
    if (RegExp(r'^[-–•]\s+').hasMatch(trimmed)) {
      body = trimmed.replaceFirst(RegExp(r'^[-–•]\s+'), '');
    }
    out.add('$n. $body');
    n++;
  }
  return out.join('\n');
}

String _numberPlainObjectiveLines(List<String> lines) {
  final out = <String>[];
  var firstNonEmpty = false;
  var n = 1;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      out.add('');
      continue;
    }
    if (!firstNonEmpty) {
      firstNonEmpty = true;
      out.add(line);
      continue;
    }
    if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
      out.add(line);
      continue;
    }
    var body = trimmed;
    if (RegExp(r'^[-–•]\s+').hasMatch(trimmed)) {
      body = trimmed.replaceFirst(RegExp(r'^[-–•]\s+'), '');
    }
    out.add('$n. $body');
    n++;
  }
  return out.join('\n');
}

bool _looksLikeLabelLine(String trimmed) {
  if (trimmed.startsWith('**')) return false;
  final i = trimmed.indexOf(':');
  if (i <= 0 || i >= trimmed.length - 1) return false;
  if (RegExp(r'\d\s*:\s*\d').hasMatch(trimmed)) return false;
  final rest = trimmed.substring(i + 1).trimLeft();
  if (rest.isNotEmpty && RegExp(r'^\d').hasMatch(rest)) return false;
  final label = trimmed.substring(0, i).trim();
  return label.length <= 90 && label.isNotEmpty;
}

List<pw.TextSpan> _pdfSpans(String s, pw.TextStyle t, pw.TextStyle tb) {
  final parts = s.split('**');
  final out = <pw.TextSpan>[];
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty) continue;
    if (i.isOdd) {
      // Bold span — if it encodes "Label: long paragraph text" split at the colon
      // so only the label stays bold and the rest renders as normal text.
      final colonIdx = part.indexOf(':');
      final afterColon = colonIdx > 0 ? part.substring(colonIdx + 1) : '';
      if (colonIdx > 0 && afterColon.trim().length > 20) {
        out.add(pw.TextSpan(text: part.substring(0, colonIdx + 1), style: tb));
        out.add(pw.TextSpan(text: afterColon, style: t));
      } else {
        out.add(pw.TextSpan(text: part, style: tb));
      }
    } else {
      out.add(pw.TextSpan(text: part, style: t));
    }
  }
  if (out.isEmpty) {
    return [pw.TextSpan(text: ' ', style: t)];
  }
  return out;
}

pw.Widget _pdfRichLine(String line, pw.TextStyle t, pw.TextStyle tb) {
  return pw.RichText(
    text: pw.TextSpan(children: _pdfSpans(line, t, tb)),
    textAlign: pw.TextAlign.left,
  );
}

pw.Widget _pdfBulletRow(String content, pw.TextStyle t, pw.TextStyle tb) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 14,
        child: pw.Text('\u2022', style: tb),
      ),
      pw.Expanded(child: _pdfRichLine(content, t, tb)),
    ],
  );
}

pw.Widget _pdfNumberedRow(String n, String content, pw.TextStyle t, pw.TextStyle tb) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 18,
        child: pw.Text('$n.', style: tb),
      ),
      pw.Expanded(child: _pdfRichLine(content, t, tb)),
    ],
  );
}

pw.Widget _pdfLabelLine(String label, String rest, pw.TextStyle t, pw.TextStyle tb) {
  return pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(text: '$label: ', style: tb),
        ..._pdfSpans(rest, t, tb),
      ],
    ),
    textAlign: pw.TextAlign.left,
  );
}

List<pw.Widget> _bodyWidgets(String body, pw.TextStyle t, pw.TextStyle tb) {
  final out = <pw.Widget>[];
  for (final raw in body.replaceAll('\r\n', '\n').split('\n')) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      out.add(pw.SizedBox(height: 4));
      continue;
    }
    final dashBullet = RegExp(r'^[-–•]\s+(.+)$').firstMatch(trimmed);
    if (dashBullet != null) {
      out.add(_pdfBulletRow(dashBullet.group(1)!, t, tb));
      out.add(pw.SizedBox(height: 2));
      continue;
    }
    final starBullet = RegExp(r'^\*\s+(.+)$').firstMatch(trimmed);
    if (starBullet != null) {
      out.add(_pdfBulletRow(starBullet.group(1)!, t, tb));
      out.add(pw.SizedBox(height: 2));
      continue;
    }
    final numM = RegExp(r'^(\d+)[\).]\s+(.+)$').firstMatch(trimmed);
    if (numM != null) {
      out.add(_pdfNumberedRow(numM.group(1)!, numM.group(2)!, t, tb));
      out.add(pw.SizedBox(height: 2));
      continue;
    }
    if (_looksLikeLabelLine(trimmed)) {
      final i = trimmed.indexOf(':');
      final label = trimmed.substring(0, i).trim();
      final rest = trimmed.substring(i + 1).trimLeft();
      out.add(_pdfLabelLine(label, rest, t, tb));
      out.add(pw.SizedBox(height: 3));
      continue;
    }
    out.add(_pdfRichLine(trimmed, t, tb));
    out.add(pw.SizedBox(height: 2));
  }
  if (out.isEmpty) {
    return [pw.Text(' ', style: t)];
  }
  return out;
}

class LessonPlanPdf {
  static String _ordinalDate(DateTime d) {
    final n = d.day;
    final suf = (n >= 11 && n <= 13)
        ? 'th'
        : switch (n % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$n$suf ${DateFormat('MMMM, yyyy').format(d)}';
  }

  static Future<Uint8List> build({
    required LessonPlanInput input,
    required LessonPlanGenerated gen,
  }) async {
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final doc = pw.Document();
    final t = pw.TextStyle(font: baseFont, fontSize: 9, lineSpacing: 1.2);
    final th = pw.TextStyle(font: boldFont, fontSize: 9, lineSpacing: 1.2);
    const border = pw.TableBorder(
      left: pw.BorderSide(width: 0.5, color: PdfColors.black),
      right: pw.BorderSide(width: 0.5, color: PdfColors.black),
      top: pw.BorderSide(width: 0.5, color: PdfColors.black),
      bottom: pw.BorderSide(width: 0.5, color: PdfColors.black),
      horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.black),
      verticalInside: pw.BorderSide(width: 0.5, color: PdfColors.black),
    );

    pw.Widget hdrCell(String a, {int flex = 1}) {
      return pw.Expanded(
        flex: flex,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(a, style: th),
        ),
      );
    }

    pw.Widget valCell(String a, {int flex = 1}) {
      return pw.Expanded(
        flex: flex,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(a, style: t),
        ),
      );
    }

    pw.Widget block(String title, String body) {
      return pw.Table(
        border: border,
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
        columnWidths: {0: const pw.FlexColumnWidth(1)},
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(title, style: th),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(5, 0, 5, 5),
                alignment: pw.Alignment.topLeft,
                child: body.trim().isEmpty
                    ? pw.Text(' ', style: t)
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: _bodyWidgets(body, t, th),
                      ),
              ),
            ],
          ),
        ],
      );
    }

    pw.Widget criticalEvaluationEmpty() {
      return pw.Table(
        border: border,
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
        columnWidths: {0: const pw.FlexColumnWidth(1)},
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Critical Evaluation:', style: th),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Container(
                height: 88,
                padding: const pw.EdgeInsets.fromLTRB(5, 4, 5, 10),
                alignment: pw.Alignment.topLeft,
                child: pw.Text(' ', style: t),
              ),
            ],
          ),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (context) => [
          if (input.institutionName.isNotEmpty)
            pw.Text(
              input.institutionName,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 11,
              ),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 6),
          pw.Text(
            'DAILY LESSON PLAN',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 13,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: border,
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
            children: [
              pw.TableRow(
                children: [
                  hdrCell('Academic Session:'),
                  valCell(input.academicSession),
                  hdrCell('Week #:'),
                  valCell(input.week),
                ],
              ),
              pw.TableRow(
                children: [
                  hdrCell('Planner:'),
                  valCell(input.plannerNo),
                  hdrCell('Developed By:'),
                  valCell(input.teacherName),
                ],
              ),
            ],
          ),
          pw.Table(
            border: border,
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
            children: [
              pw.TableRow(
                children: [
                  hdrCell('Date:'),
                  valCell(input.date != null ? _ordinalDate(input.date!) : ''),
                  hdrCell('Subject:'),
                  valCell(input.subject),
                ],
              ),
              pw.TableRow(
                children: [
                  hdrCell('Class:'),
                  valCell(input.className),
                  hdrCell('Period/Duration:'),
                  valCell(input.periodDuration),
                ],
              ),
            ],
          ),
          pw.Table(
            border: border,
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                children: [
                  hdrCell('Unit:'),
                  valCell(input.unit),
                  hdrCell('Title:'),
                  valCell(input.title),
                ],
              ),
            ],
          ),
          pw.Table(
            border: border,
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                children: [
                  hdrCell('Topics:'),
                  valCell(input.topicsLine),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          block(
            'Lesson Objectives:',
            _ensureNumberedLessonObjectives(gen.lessonObjectives),
          ),
          pw.SizedBox(height: 3),
          block('Skills Focused On:', gen.skillsFocusedOn),
          pw.SizedBox(height: 3),
          block('Resources:', gen.resources),
          pw.SizedBox(height: 3),
          block('Methodology:', gen.methodology),
          pw.SizedBox(height: 3),
          block('Prior Knowledge:', 'Relevant questions will be asked. These questions are mentioned in AFL.'),
          pw.SizedBox(height: 3),
          block('Explanation:', gen.explanation),
          pw.SizedBox(height: 3),
          block('ACTIVITY:', gen.activity),
          pw.SizedBox(height: 3),
          block('Wrap-Up:', gen.wrapUp),
          pw.SizedBox(height: 3),
          block('AOL:', gen.aol),
          pw.SizedBox(height: 3),
          block('C.W:', gen.classWork),
          pw.SizedBox(height: 3),
          block('H.W:', gen.homework),
          pw.SizedBox(height: 3),
          block(
            'AFL:',
            '**Prior Knowledge:**\n${gen.priorKnowledge}\n\n**Explanation:**\n${gen.afl}',
          ),
          pw.SizedBox(height: 3),
          block('Differentiation:', gen.differentiation),
          pw.SizedBox(height: 3),
          criticalEvaluationEmpty(),
          pw.SizedBox(height: 14),
          pw.Table(
            border: border,
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
            children: [
              pw.TableRow(
                children: [
                  hdrCell('Teacher Sign:'),
                  valCell('________________________'),
                  hdrCell('Co-Ordinator Sign:'),
                  valCell('________________________'),
                ],
              ),
              pw.TableRow(
                children: [
                  hdrCell('HM Sign:'),
                  valCell('________________________'),
                  hdrCell(''),
                  valCell(''),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }
}
