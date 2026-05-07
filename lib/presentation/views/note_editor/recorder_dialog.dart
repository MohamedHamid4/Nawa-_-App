import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

class RecorderResult {
  final String path;
  final int durationMs;
  final String transcript;
  RecorderResult({
    required this.path,
    required this.durationMs,
    required this.transcript,
  });
}

class RecorderDialog extends ConsumerStatefulWidget {
  final String localeId;
  const RecorderDialog({super.key, required this.localeId});

  @override
  ConsumerState<RecorderDialog> createState() => _RecorderDialogState();
}

class _RecorderDialogState extends ConsumerState<RecorderDialog> {
  String? _path;
  String _transcript = '';
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final voice = ref.read(voiceServiceProvider);
    final path = await voice.startRecording();
    if (path == null) {
      if (mounted) Navigator.of(context).pop(null);
      return;
    }
    setState(() {
      _path = path;
      _recording = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });
    await voice.startTranscribing(
      localeId: widget.localeId,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _transcript = text);
      },
    );
  }

  Future<void> _stop({bool cancel = false}) async {
    final voice = ref.read(voiceServiceProvider);
    _timer?.cancel();
    _timer = null;
    await voice.stopTranscribing();
    final path = await voice.stopRecording();
    if (cancel) {
      if (mounted) Navigator.of(context).pop(null);
      return;
    }
    if (mounted) {
      Navigator.of(context).pop(
        RecorderResult(
          path: path ?? _path ?? '',
          durationMs: _elapsed.inMilliseconds,
          transcript: _transcript,
        ),
      );
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text('note.blocks.audio'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _recording ? Icons.mic : Icons.mic_off,
              size: 48,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(_format(_elapsed),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                _transcript.isEmpty
                    ? 'note.blocks.transcript'.tr()
                    : _transcript,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _stop(cancel: true),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton.icon(
          onPressed: () => _stop(),
          icon: const Icon(Icons.stop),
          label: Text('note.blocks.stop'.tr()),
        ),
      ],
    );
  }
}
