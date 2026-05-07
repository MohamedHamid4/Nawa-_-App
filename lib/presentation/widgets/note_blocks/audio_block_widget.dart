import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/note_block.dart';

class AudioBlockWidget extends StatefulWidget {
  final AudioBlock block;
  final ValueChanged<AudioBlock> onChanged;
  final VoidCallback onRemove;

  const AudioBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<AudioBlockWidget> createState() => _AudioBlockWidgetState();
}

class _AudioBlockWidgetState extends State<AudioBlockWidget> {
  final AudioPlayer _player = AudioPlayer();
  late final TextEditingController _transcript;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _transcript = TextEditingController(text: widget.block.transcript);
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
  }

  @override
  void didUpdateWidget(covariant AudioBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _transcript.text = widget.block.transcript;
    }
  }

  @override
  void dispose() {
    _transcript.dispose();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (widget.block.localPath != null && File(widget.block.localPath!).existsSync()) {
      await _player.play(DeviceFileSource(widget.block.localPath!));
    } else if (widget.block.remoteUrl != null && widget.block.remoteUrl!.isNotEmpty) {
      await _player.play(UrlSource(widget.block.remoteUrl!));
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMs = _duration.inMilliseconds == 0
        ? widget.block.durationMs.toDouble()
        : _duration.inMilliseconds.toDouble();
    final value = _position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconButton(
                  iconSize: 36,
                  icon: Icon(_playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill),
                  color: scheme.primary,
                  onPressed: _toggle,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Slider(
                        value: value,
                        max: maxMs == 0 ? 1 : maxMs,
                        onChanged: (v) {
                          _player.seek(Duration(milliseconds: v.toInt()));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_format(_position),
                                style: Theme.of(context).textTheme.labelSmall),
                            Text(_format(Duration(milliseconds: maxMs.toInt())),
                                style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('note.blocks.transcript'.tr(),
              style: Theme.of(context).textTheme.labelMedium),
          TextField(
            controller: _transcript,
            maxLines: null,
            minLines: 1,
            decoration: const InputDecoration(
              isDense: true,
            ),
            onChanged: (v) =>
                widget.onChanged(widget.block.copyWith(transcript: v)),
          ),
        ],
      ),
    );
  }
}
