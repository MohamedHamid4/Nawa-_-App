import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' as rec;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';

class VoiceService {
  final rec.AudioRecorder _recorder = rec.AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  static const _uuid = Uuid();

  bool _speechReady = false;
  bool _transcribing = false;

  Future<bool> hasMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String?> startRecording() async {
    try {
      if (!await hasMicPermission()) return null;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${_uuid.v4()}.m4a';
      await _recorder.start(
        const rec.RecordConfig(
          encoder: rec.AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      return path;
    } catch (e, st) {
      AppLogger.e('startRecording', e, st);
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      AppLogger.w('stopRecording: $e');
      return null;
    }
  }

  Future<void> startTranscribing({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) => AppLogger.d('speech status: $s'),
        onError: (e) => AppLogger.w('speech error: $e'),
      );
      if (!_speechReady) return;
      _transcribing = true;
      await _speech.listen(
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
        ),
        onResult: (r) {
          onResult(r.recognizedWords, r.finalResult);
        },
      );
    } catch (e, st) {
      AppLogger.e('startTranscribing', e, st);
    }
  }

  Future<void> stopTranscribing() async {
    if (!_transcribing) return;
    _transcribing = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<int> durationMs(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return 0;
    } catch (_) {}
    return 0;
  }

  Future<void> dispose() async {
    try {
      await _recorder.dispose();
    } catch (_) {}
    try {
      await _speech.stop();
    } catch (_) {}
  }
}
