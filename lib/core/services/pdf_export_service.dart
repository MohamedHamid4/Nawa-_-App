import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_block.dart';

/// Generates a beautifully designed PDF for a note. Embeds Cairo (Google
/// Fonts) so Arabic glyphs render correctly instead of rendering as boxes.
class PdfExportService {
  static final _brandColor = PdfColor.fromInt(0xFF4D9180);
  static final _goldColor = PdfColor.fromInt(0xFFC9A75C);
  static final _grayDark = PdfColor.fromInt(0xFF2C3140);
  static final _grayLight = PdfColor.fromInt(0xFF8B92A3);

  static Future<Uint8List> generateNotePdf(Note note) async {
    final regularFont = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final isArabic = RegExp(r'[؀-ۿ]').hasMatch(
      note.title + note.blocks.map(_blockToPlainText).join(' '),
    );

    final pdf = pw.Document(
      title: note.title.isEmpty ? 'Nawa Note' : note.title,
      author: 'Nawa',
      creator: 'Nawa - نواة',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 56, 48, 56),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        textDirection:
            isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (context) =>
            _buildHeader(context, isArabic, regularFont, boldFont),
        footer: (context) => _buildFooter(context, isArabic, regularFont),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Text(
            note.title.isEmpty
                ? (isArabic ? 'بدون عنوان' : 'Untitled Note')
                : note.title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: _grayDark,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildMeta(note, regularFont, isArabic),
          pw.SizedBox(height: 24),
          _buildDivider(),
          pw.SizedBox(height: 24),
          ..._buildBlocks(note.blocks, regularFont, boldFont, isArabic),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMeta(Note note, pw.Font font, bool isArabic) {
    return pw.Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE8F1EE),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _formatDate(note.updatedAt, isArabic),
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _brandColor,
            ),
          ),
        ),
        ...note.tags.map(
          (tag) => pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              '#$tag',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      height: 2,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_brandColor, _goldColor, _brandColor],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.Context context,
    bool isArabic,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              _buildLogoIcon(),
              pw.SizedBox(width: 8),
              pw.Text(
                isArabic ? 'نواة' : 'Nawa',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 16,
                  color: _brandColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Text(
            isArabic ? 'مذكرة' : 'Note',
            style: pw.TextStyle(
              font: regular,
              fontSize: 10,
              color: _grayLight,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLogoIcon() {
    return pw.Container(
      width: 28,
      height: 28,
      decoration: pw.BoxDecoration(
        color: _brandColor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 8, height: 1.5, color: PdfColors.white),
          pw.Container(width: 16, height: 1.5, color: PdfColors.white),
          pw.Container(width: 12, height: 1.5, color: PdfColors.white),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context,
    bool isArabic,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isArabic ? 'تم الإنشاء بـ نواة' : 'Made with Nawa',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _grayLight,
            ),
          ),
          pw.Text(
            isArabic
                ? 'صفحة ${context.pageNumber} من ${context.pagesCount}'
                : 'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: _grayLight,
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _buildBlocks(
    List<NoteBlock> blocks,
    pw.Font regular,
    pw.Font bold,
    bool isArabic,
  ) {
    final out = <pw.Widget>[];
    for (final block in blocks) {
      switch (block) {
        case TextBlock b:
          if (b.text.trim().isEmpty) {
            out.add(pw.SizedBox(height: 4));
            break;
          }
          switch (b.style) {
            case TextStyleHint.heading:
              out.add(pw.Padding(
                padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
                child: pw.Text(
                  b.text,
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _grayDark,
                  ),
                ),
              ));
            case TextStyleHint.subheading:
              out.add(pw.Padding(
                padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
                child: pw.Text(
                  b.text,
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: _grayDark,
                  ),
                ),
              ));
            case TextStyleHint.quote:
              out.add(pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                    left: pw.BorderSide(color: _brandColor, width: 3),
                  ),
                ),
                child: pw.Text(
                  b.text,
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    color: _grayDark,
                  ),
                ),
              ));
            case TextStyleHint.code:
              out.add(pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey900,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  b.text,
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ));
            case TextStyleHint.body:
              out.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  b.text,
                  style: pw.TextStyle(
                    font: regular,
                    fontSize: 12,
                    lineSpacing: 1.7,
                    color: _grayDark,
                  ),
                ),
              ));
          }

        case ChecklistBlock b:
          out.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: b.items
                  .map(
                    (item) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 14,
                            height: 14,
                            margin: const pw.EdgeInsets.only(
                              top: 2,
                              right: 8,
                              left: 8,
                            ),
                            decoration: pw.BoxDecoration(
                              color: item.done
                                  ? _brandColor
                                  : PdfColor.fromInt(0x00FFFFFF),
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(
                                color: _brandColor,
                                width: 1.5,
                              ),
                            ),
                            child: item.done
                                ? pw.Center(
                                    child: pw.Text(
                                      '✓',
                                      style: pw.TextStyle(
                                        font: bold,
                                        fontSize: 9,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              item.text,
                              style: pw.TextStyle(
                                font: regular,
                                fontSize: 12,
                                lineSpacing: 1.5,
                                decoration: item.done
                                    ? pw.TextDecoration.lineThrough
                                    : null,
                                color: item.done ? _grayLight : _grayDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ));

        case LinkBlock b:
          out.add(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.UrlLink(
              destination: b.url,
              child: pw.Text(
                b.title?.isNotEmpty == true ? '${b.title}\n${b.url}' : b.url,
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 12,
                  color: PdfColors.blue,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
          ));

        case ImageBlock b:
          out.add(pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Text('📷', style: pw.TextStyle(font: regular, fontSize: 14)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    b.caption.isNotEmpty
                        ? b.caption
                        : (isArabic ? 'صورة مرفقة' : 'Attached image'),
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 11,
                      color: _grayLight,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ));

        case VideoBlock b:
          out.add(pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Text('🎬', style: pw.TextStyle(font: regular, fontSize: 14)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    b.caption.isNotEmpty
                        ? b.caption
                        : (isArabic ? 'فيديو مرفق' : 'Attached video'),
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 11,
                      color: _grayLight,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ));

        case AudioBlock b:
          out.add(pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('🎙️',
                    style: pw.TextStyle(font: regular, fontSize: 14)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    b.transcript.isNotEmpty
                        ? b.transcript
                        : (isArabic ? 'تسجيل صوتي' : 'Audio recording'),
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 11,
                      color: _grayDark,
                    ),
                  ),
                ),
              ],
            ),
          ));

        case FileBlock b:
          out.add(pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Text('📎',
                    style: pw.TextStyle(font: regular, fontSize: 14)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    b.fileName,
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 11,
                      color: _grayLight,
                    ),
                  ),
                ),
              ],
            ),
          ));
      }
    }
    return out;
  }

  static String _blockToPlainText(NoteBlock block) {
    return switch (block) {
      TextBlock b => b.text,
      ChecklistBlock b => b.items.map((i) => i.text).join(' '),
      ImageBlock b => b.caption,
      VideoBlock b => b.caption,
      AudioBlock b => b.transcript,
      FileBlock b => b.fileName,
      LinkBlock b => '${b.title ?? ''} ${b.url}',
    };
  }

  static String _formatDate(DateTime date, bool isArabic) {
    try {
      final formatter = DateFormat(
        isArabic ? 'd MMMM yyyy' : 'MMMM d, yyyy',
        isArabic ? 'ar' : 'en',
      );
      return formatter.format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  /// Save PDF to the device's Downloads folder (or app docs as fallback).
  static Future<File> saveToDownloads(Note note) async {
    final bytes = await generateNotePdf(note);
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    final safeTitle = note.title.isEmpty
        ? 'Nawa_Note'
        : note.title
            .replaceAll(RegExp(r'[^\w\s؀-ۿ-]'), '')
            .trim();
    final fileName =
        '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}
