import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/note_block.dart';

class ImageBlockWidget extends StatefulWidget {
  final ImageBlock block;
  final ValueChanged<ImageBlock> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onOcr;

  const ImageBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
    this.onOcr,
  });

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  late final TextEditingController _caption;

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(text: widget.block.caption);
  }

  @override
  void didUpdateWidget(covariant ImageBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _caption.text = widget.block.caption;
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget image;
    if (widget.block.localPath != null && File(widget.block.localPath!).existsSync()) {
      image = Image.file(File(widget.block.localPath!), fit: BoxFit.cover);
    } else if (widget.block.remoteUrl != null && widget.block.remoteUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: widget.block.remoteUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: scheme.surfaceContainerHighest,
          height: 180,
        ),
      );
    } else {
      image = Container(
        height: 180,
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.image_outlined, size: 48, color: scheme.onSurface.withValues(alpha: 0.4)),
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
                child: AspectRatio(aspectRatio: 16 / 9, child: image),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onOcr != null)
                        IconButton(
                          tooltip: 'ai.ocr'.tr(),
                          icon: const Icon(Icons.text_fields, color: Colors.white),
                          onPressed: widget.onOcr,
                        ),
                      IconButton(
                        tooltip: 'note.blocks.remove'.tr(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onRemove,
                      ),
                    ],
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
