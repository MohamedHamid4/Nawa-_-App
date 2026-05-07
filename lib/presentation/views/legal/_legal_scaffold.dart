import 'package:flutter/material.dart';

import '../../../core/extensions/extensions.dart';
import '../../../core/utils/responsive.dart';

class LegalScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? heroIcon;
  final String? heroImage;
  final List<Widget> children;

  const LegalScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.heroIcon,
    this.heroImage,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = context.responsive<double>(
      phone: 200,
      smallPhone: 170,
      tablet: 240,
      largeTablet: 280,
    );
    final heroIconSize = context.responsive<double>(
      phone: 56,
      smallPhone: 44,
      tablet: 72,
      largeTablet: 88,
    );
    final heroImageSize = context.responsive<double>(
      phone: 64,
      smallPhone: 50,
      tablet: 88,
      largeTablet: 104,
    );
    final horizontalPad = context.responsive<double>(
      phone: 20,
      smallPhone: 16,
      tablet: 32,
      largeTablet: 48,
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: heroHeight,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.colors.primary,
                        context.colors.primary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 56),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (heroImage != null)
                            Image.asset(
                              heroImage!,
                              width: heroImageSize,
                              height: heroImageSize,
                            )
                          else if (heroIcon != null)
                            Icon(
                              heroIcon,
                              size: heroIconSize,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                20,
                horizontalPad,
                40,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            style: context.text.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const LegalSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class LegalParagraph extends StatelessWidget {
  final String text;
  final bool bold;
  const LegalParagraph(this.text, {super.key, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: context.text.bodyLarge?.copyWith(
          height: 1.7,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class LegalBullet extends StatelessWidget {
  final String text;
  const LegalBullet(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8, end: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyLarge?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
