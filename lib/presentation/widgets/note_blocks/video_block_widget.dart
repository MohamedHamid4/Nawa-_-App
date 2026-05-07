import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/entities/note_block.dart';

class VideoBlockWidget extends StatefulWidget {
  final VideoBlock block;
  final ValueChanged<VideoBlock> onChanged;
  final VoidCallback onRemove;

  const VideoBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<VideoBlockWidget> createState() => _VideoBlockWidgetState();
}

class _VideoBlockWidgetState extends State<VideoBlockWidget> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  late final TextEditingController _caption;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(text: widget.block.caption);
    _setup();
  }

  Future<void> _setup() async {
    try {
      VideoPlayerController? controller;
      if (widget.block.localPath != null &&
          File(widget.block.localPath!).existsSync()) {
        controller = VideoPlayerController.file(File(widget.block.localPath!));
      } else if (widget.block.remoteUrl != null &&
          widget.block.remoteUrl!.isNotEmpty) {
        controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.block.remoteUrl!));
      }
      if (controller == null) {
        if (mounted) setState(() => _initializing = false);
        return;
      }
      await controller.initialize();
      _video = controller;
      _chewie = ChewieController(
        videoPlayerController: controller,
        autoInitialize: true,
        looping: false,
        autoPlay: false,
        aspectRatio: controller.value.aspectRatio,
      );
      if (mounted) setState(() => _initializing = false);
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget body;
    if (_initializing) {
      body = AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: scheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_chewie != null && _video?.value.isInitialized == true) {
      body = AspectRatio(
        aspectRatio: _video!.value.aspectRatio,
        child: Chewie(controller: _chewie!),
      );
    } else {
      body = AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.videocam_off,
              color: scheme.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: body,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onRemove,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _caption,
            decoration: InputDecoration(
              hintText: 'note.blocks.caption_hint'.tr(),
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (v) =>
                widget.onChanged(widget.block.copyWith(caption: v)),
          ),
        ],
      ),
    );
  }
}
