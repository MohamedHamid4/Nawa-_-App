import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../domain/entities/note_block.dart';

class LinkBlockWidget extends ConsumerStatefulWidget {
  final LinkBlock block;
  final ValueChanged<LinkBlock> onChanged;
  final VoidCallback onRemove;

  const LinkBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  ConsumerState<LinkBlockWidget> createState() => _LinkBlockWidgetState();
}

class _LinkBlockWidgetState extends ConsumerState<LinkBlockWidget> {
  late final TextEditingController _urlCtrl;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.block.url);
    if (widget.block.url.isNotEmpty &&
        widget.block.title == null &&
        widget.block.description == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPreview());
    }
  }

  @override
  void didUpdateWidget(covariant LinkBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _urlCtrl.text = widget.block.url;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || _fetching) return;
    setState(() => _fetching = true);
    final preview = await ref.read(linkPreviewServiceProvider).fetch(url);
    setState(() => _fetching = false);
    widget.onChanged(widget.block.copyWith(
      url: url,
      title: preview.title,
      description: preview.description,
      imageUrl: preview.imageUrl,
    ));
  }

  Future<void> _open() async {
    final url = widget.block.url;
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPreview = widget.block.title != null || widget.block.description != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'note.blocks.url_hint'.tr(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.link, size: 18),
                  ),
                  onSubmitted: (_) => _fetchPreview(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _fetching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'common.retry'.tr(),
                onPressed: _fetchPreview,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          if (hasPreview)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: _open,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.block.imageUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: widget.block.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: scheme.surface,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.block.title != null)
                              Text(
                                widget.block.title!,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (widget.block.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.block.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
