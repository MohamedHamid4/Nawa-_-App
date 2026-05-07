import 'package:flutter/material.dart';

enum AppButtonVariant { primary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? scheme.onPrimary
                  : scheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

    Widget btn;
    switch (variant) {
      case AppButtonVariant.primary:
        btn = FilledButton(
          onPressed: disabled ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color ?? scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
          child: child,
        );
      case AppButtonVariant.outline:
        btn = OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? scheme.onSurface,
          ),
          child: child,
        );
      case AppButtonVariant.text:
        btn = TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color ?? scheme.primary,
          ),
          child: child,
        );
    }

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
