import 'package:flutter/material.dart';

/// A Row that auto-wraps Text children with Flexible to prevent overflow.
/// Use anywhere a Row contains text that might be longer than its container.
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        if (child is Text) {
          return Flexible(
            child: Text(
              child.data ?? '',
              style: child.style,
              maxLines: child.maxLines ?? 1,
              overflow: child.overflow ?? TextOverflow.ellipsis,
              textAlign: child.textAlign,
              textDirection: child.textDirection,
            ),
          );
        }
        return child;
      }).toList(),
    );
  }
}
