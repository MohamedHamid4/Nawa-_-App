import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/note_font_styles.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/note_block.dart';

class TextBlockWidget extends StatefulWidget {
  final TextBlock block;
  final ValueChanged<TextBlock> onChanged;
  final VoidCallback onRemove;
  final NoteFontStyle noteFontStyle;

  const TextBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
    this.noteFontStyle = NoteFontStyle.defaultStyle,
  });

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late final TextEditingController _controller;
  late TextStyleHint _style;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.text);
    _style = widget.block.style;
  }

  @override
  void didUpdateWidget(covariant TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _controller.text = widget.block.text;
      _style = widget.block.style;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _styleFor(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isArabic = context.locale.languageCode == 'ar';
    switch (_style) {
      case TextStyleHint.heading:
        return NoteFontStyles.getStyle(
          style: widget.noteFontStyle,
          isArabic: isArabic,
          fontSize: 24,
        ).copyWith(fontWeight: FontWeight.w800);
      case TextStyleHint.subheading:
        return NoteFontStyles.getStyle(
          style: widget.noteFontStyle,
          isArabic: isArabic,
          fontSize: 20,
        ).copyWith(fontWeight: FontWeight.w700);
      case TextStyleHint.body:
        return NoteFontStyles.getStyle(
          style: widget.noteFontStyle,
          isArabic: isArabic,
          fontSize: 16,
        );
      case TextStyleHint.quote:
        return NoteFontStyles.getStyle(
          style: widget.noteFontStyle,
          isArabic: isArabic,
          fontSize: 16,
        ).copyWith(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.secondary,
        );
      case TextStyleHint.code:
        return t.bodyMedium!.copyWith(
          fontFamily: 'monospace',
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
        );
    }
  }

  String _hintFor() {
    switch (_style) {
      case TextStyleHint.heading:
        return 'note.blocks.heading'.tr();
      case TextStyleHint.subheading:
        return 'note.blocks.subheading'.tr();
      case TextStyleHint.quote:
        return 'note.blocks.quote'.tr();
      case TextStyleHint.code:
        return 'note.blocks.code'.tr();
      case TextStyleHint.body:
        return 'note.blocks.text'.tr();
    }
  }

  void _setStyle(TextStyleHint s) {
    setState(() => _style = s);
    widget.onChanged(widget.block.copyWith(text: _controller.text, style: s));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: _style == TextStyleHint.quote
              ? BorderSide(color: scheme.tertiary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StyleChip(
                icon: Icons.title,
                selected: _style == TextStyleHint.heading,
                onTap: () => _setStyle(TextStyleHint.heading),
              ),
              const SizedBox(width: 6),
              _StyleChip(
                icon: Icons.text_fields,
                selected: _style == TextStyleHint.subheading,
                onTap: () => _setStyle(TextStyleHint.subheading),
              ),
              const SizedBox(width: 6),
              _StyleChip(
                icon: Icons.notes,
                selected: _style == TextStyleHint.body,
                onTap: () => _setStyle(TextStyleHint.body),
              ),
              const SizedBox(width: 6),
              _StyleChip(
                icon: Icons.format_quote,
                selected: _style == TextStyleHint.quote,
                onTap: () => _setStyle(TextStyleHint.quote),
              ),
              const SizedBox(width: 6),
              _StyleChip(
                icon: Icons.code,
                selected: _style == TextStyleHint.code,
                onTap: () => _setStyle(TextStyleHint.code),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'note.blocks.remove'.tr(),
                icon: const Icon(Icons.close, size: 18),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          TextField(
            controller: _controller,
            style: _styleFor(context),
            maxLines: null,
            minLines: 1,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _hintFor(),
              border: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) {
              widget.onChanged(
                widget.block.copyWith(text: v, style: _style),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StyleChip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
