import 'package:flutter/material.dart';

/// Device size buckets for responsive layouts.
enum DeviceSize { smallPhone, phone, largePhone, tablet, largeTablet }

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get safePadding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Available content height (excluding system bars and keyboard).
  double get contentHeight =>
      screenHeight - safePadding.top - safePadding.bottom - viewInsets.bottom;

  DeviceSize get deviceSize {
    final w = screenWidth;
    if (w < 340) return DeviceSize.smallPhone;
    if (w < 400) return DeviceSize.phone;
    if (w < 600) return DeviceSize.largePhone;
    if (w < 900) return DeviceSize.tablet;
    return DeviceSize.largeTablet;
  }

  bool get isSmallPhone => deviceSize == DeviceSize.smallPhone;
  bool get isPhone => deviceSize.index <= DeviceSize.largePhone.index;
  bool get isTablet => deviceSize.index >= DeviceSize.tablet.index;

  /// Pick a value based on device size.
  T responsive<T>({
    required T phone,
    T? smallPhone,
    T? largePhone,
    T? tablet,
    T? largeTablet,
  }) {
    switch (deviceSize) {
      case DeviceSize.smallPhone:
        return smallPhone ?? phone;
      case DeviceSize.phone:
        return phone;
      case DeviceSize.largePhone:
        return largePhone ?? phone;
      case DeviceSize.tablet:
        return tablet ?? largePhone ?? phone;
      case DeviceSize.largeTablet:
        return largeTablet ?? tablet ?? largePhone ?? phone;
    }
  }

  /// Scale a value by screen width (relative to a 375px design baseline).
  double scaleW(double value) =>
      (value * screenWidth / 375).clamp(value * 0.8, value * 1.4);

  /// Scale a value by screen height (relative to an 812px design baseline).
  double scaleH(double value) =>
      (value * screenHeight / 812).clamp(value * 0.8, value * 1.4);

  /// Cap a font size so it doesn't grow too large on tablets or shrink too much on small phones.
  double sp(double size) {
    final scale = (screenWidth / 375).clamp(0.85, 1.15);
    return size * scale;
  }
}

/// A widget that builds different layouts based on device size.
class Responsive extends StatelessWidget {
  final Widget phone;
  final Widget? smallPhone;
  final Widget? largePhone;
  final Widget? tablet;
  final Widget? largeTablet;

  const Responsive({
    super.key,
    required this.phone,
    this.smallPhone,
    this.largePhone,
    this.tablet,
    this.largeTablet,
  });

  @override
  Widget build(BuildContext context) {
    return context.responsive(
      phone: phone,
      smallPhone: smallPhone,
      largePhone: largePhone,
      tablet: tablet,
      largeTablet: largeTablet,
    );
  }
}

/// A scrollable column that always fits the screen and centers content when possible.
class ResponsiveScaffoldBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAlignment;

  const ResponsiveScaffoldBody({
    super.key,
    required this.children,
    this.padding,
    this.alignment = MainAxisAlignment.center,
    this.crossAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: context.responsive(
                  phone: 24.0,
                  smallPhone: 16.0,
                  tablet: 48.0,
                  largeTablet: 80.0,
                ),
                vertical: 16,
              ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: alignment,
                crossAxisAlignment: crossAlignment,
                mainAxisSize: MainAxisSize.max,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Constrains content to a max readable width (centered) — useful for forms,
/// long-form text, and detail screens on tablets.
class ResponsiveMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const ResponsiveMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
