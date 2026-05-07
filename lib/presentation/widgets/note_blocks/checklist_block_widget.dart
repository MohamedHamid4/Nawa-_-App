import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/note_block.dart';

class ChecklistBlockWidget extends StatefulWidget {
  final ChecklistBlock block;
  final ValueChanged<ChecklistBlock> onChanged;
  final VoidCallback onRemove;

  const ChecklistBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<ChecklistBlockWidget> createState() => _ChecklistBlockWidgetState();
}

class _ChecklistBlockWidgetState extends State<ChecklistBlockWidget> {
  late List<ChecklistItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.block.items);
  }

  @override
  void didUpdateWidget(covariant ChecklistBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _items = List.of(widget.block.items);
    }
  }

  void _emit() {
    widget.onChanged(widget.block.copyWith(items: List.of(_items)));
  }

  void _setItem(int index, ChecklistItem updated) {
    _items[index] = updated;
    _emit();
  }

  void _addItem() {
    setState(() => _items.add(ChecklistItem.create('')));
    _emit();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    if (_items.isEmpty) widget.onRemove();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_box_outlined, size: 18,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('note.blocks.checklist'.tr(),
                  style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'note.blocks.remove'.tr(),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          for (int i = 0; i < _items.length; i++)
            _ChecklistRow(
              key: ValueKey(_items[i].id),
              item: _items[i],
              onChanged: (next) => _setItem(i, next),
              onRemove: () => _removeItem(i),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: Text('note.blocks.add_item'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatefulWidget {
  final ChecklistItem item;
  final ValueChanged<ChecklistItem> onChanged;
  final VoidCallback onRemove;

  const _ChecklistRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void didUpdateWidget(covariant _ChecklistRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _controller.text = widget.item.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: widget.item.done,
            onChanged: (v) => widget.onChanged(
              widget.item.copyWith(done: v ?? false),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'note.blocks.checklist_hint'.tr(),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                decoration: widget.item.done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              onChanged: (v) {
                widget.onChanged(widget.item.copyWith(text: v));
              },
            ),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
