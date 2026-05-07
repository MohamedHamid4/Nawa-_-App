import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_block.dart';
import '../utils/app_logger.dart';
import 'pdf_export_service.dart';

class ShareService {
  ShareService._();

  /// Share note as plain text. Works with WhatsApp/Telegram/etc.
  static Future<void> shareAsText(Note note) async {
    final text = _renderText(note);
    await Share.share(text, subject: note.title.isEmpty ? 'Nawa' : note.title);
  }

  /// Copy note text to system clipboard.
  static Future<void> copyToClipboard(Note note) async {
    await Clipboard.setData(ClipboardData(text: _renderText(note)));
  }

  /// Share note as a PDF file.
  static Future<void> shareAsPdf(Note note) async {
    try {
      final bytes = await PdfExportService.generateNotePdf(note);
      final dir = await getTemporaryDirectory();
      final safeName =
          (note.title.isEmpty ? 'note' : note.title).replaceAll(
        RegExp(r'[^\w\s؀-ۿ]'),
        '_',
      );
      final file = File('${dir.path}/$safeName.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: note.title.isEmpty ? 'Nawa note' : note.title,
      );
    } catch (e, st) {
      AppLogger.w('shareAsPdf failed: $e\n$st');
    }
  }

  /// Save PDF to the device's Downloads folder; returns the file or null.
  static Future<File?> downloadAsPdf(Note note) async {
    try {
      return await PdfExportService.saveToDownloads(note);
    } catch (e, st) {
      AppLogger.w('downloadAsPdf failed: $e\n$st');
      return null;
    }
  }

  static String _renderText(Note note) {
    final buffer = StringBuffer();
    if (note.title.isNotEmpty) {
      buffer.writeln('# ${note.title}');
      buffer.writeln();
    }
    for (final block in note.blocks) {
      if (block is TextBlock) {
        if (block.text.trim().isNotEmpty) {
          buffer.writeln(block.text);
          buffer.writeln();
        }
      } else if (block is ChecklistBlock) {
        for (final item in block.items) {
          buffer.writeln('${item.done ? "[x]" : "[ ]"} ${item.text}');
        }
        buffer.writeln();
      } else if (block is LinkBlock) {
        buffer.writeln(block.url);
        buffer.writeln();
      } else if (block is ImageBlock && block.caption.isNotEmpty) {
        buffer.writeln('(image) ${block.caption}');
      } else if (block is AudioBlock && block.transcript.isNotEmpty) {
        buffer.writeln('(audio) ${block.transcript}');
      } else if (block is FileBlock) {
        buffer.writeln('(file) ${block.fileName}');
      }
    }
    if (note.tags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(note.tags.map((t) => '#$t').join(' '));
    }
    return buffer.toString().trim();
  }

}
