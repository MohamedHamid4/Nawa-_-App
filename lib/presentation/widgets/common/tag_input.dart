import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? hintText;

  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  void _add(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    if (widget.tags.contains(v)) {
      _controller.clear();
      return;
    }
    final next = [...widget.tags, v];
    widget.onChanged(next);
    _controller.clear();
  }

  void _remove(String tag) {
    final next = widget.tags.where((t) => t != tag).toList();
    widget.onChanged(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in widget.tags)
          Chip(
            label: Text(tag),
            onDeleted: () => _remove(tag),
            backgroundColor: scheme.primaryContainer,
            side: BorderSide.none,
            deleteIconColor: scheme.primary,
          ),
        IntrinsicWidth(
          child: SizedBox(
            width: 140,
            child: TextField(
              controller: _controller,
              onSubmitted: _add,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hintText ?? 'note.tags_hint'.tr(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
