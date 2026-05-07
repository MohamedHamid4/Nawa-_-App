import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/utils/responsive.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const _pages = [
    _OnboardData(
      animation: 'assets/animations/onboarding_writing.json',
      titleKey: 'onboarding.p1_title',
      descKey: 'onboarding.p1_desc',
    ),
    _OnboardData(
      animation: 'assets/animations/onboarding_ai.json',
      titleKey: 'onboarding.p2_title',
      descKey: 'onboarding.p2_desc',
    ),
    _OnboardData(
      animation: 'assets/animations/onboarding_sync.json',
      titleKey: 'onboarding.p3_title',
      descKey: 'onboarding.p3_desc',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(prefsProvider).setOnboardingDone();
    if (!mounted) return;
    context.go(AppRoutes.signIn);
  }

  void _next() {
    if (_currentIndex == _pages.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _pages.length - 1;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, end: 12),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    child: Text(
                      'onboarding.skip'.tr(),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) => _OnboardingPage(data: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentIndex ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? colors.primary : colors.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.responsive(phone: 24.0, smallPhone: 16.0, tablet: 48.0),
                8,
                context.responsive(phone: 24.0, smallPhone: 16.0, tablet: 48.0),
                context.responsive(phone: 32.0, smallPhone: 20.0),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive(phone: 480.0, tablet: 480.0),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: context.responsive(phone: 56.0, smallPhone: 48.0),
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          isLast
                              ? 'onboarding.start'.tr()
                              : 'onboarding.next'.tr(),
                          key: ValueKey(isLast),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

class _OnboardData {
  final String animation;
  final String titleKey;
  final String descKey;

  const _OnboardData({
    required this.animation,
    required this.titleKey,
    required this.descKey,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final animSize = context.responsive<double>(
      phone: 220,
      smallPhone: 160,
      largePhone: 260,
      tablet: 320,
      largeTablet: 380,
    );

    final titleSize = context.responsive<double>(
      phone: 24,
      smallPhone: 20,
      largePhone: 28,
      tablet: 32,
      largeTablet: 36,
    );

    final descSize = context.responsive<double>(
      phone: 14,
      smallPhone: 13,
      largePhone: 16,
      tablet: 17,
      largeTablet: 18,
    );

    return ResponsiveScaffoldBody(
      padding: EdgeInsets.symmetric(
        horizontal:
            context.responsive(phone: 24.0, smallPhone: 16.0, tablet: 64.0),
        vertical: 8,
      ),
      children: [
        const Spacer(),
        SizedBox(
          width: animSize,
          height: animSize,
          child: FutureBuilder<LottieComposition>(
            future: AssetLottie(data.animation).load(),
            builder: (context, snap) {
              if (snap.hasError || (!snap.hasData && snap.connectionState != ConnectionState.waiting)) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: animSize * 0.4,
                    color: colors.primary,
                  ),
                );
              }
              if (!snap.hasData) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                );
              }
              return Lottie(
                composition: snap.data,
                fit: BoxFit.contain,
                repeat: true,
              );
            },
          ),
        ),
        SizedBox(
          height:
              context.responsive(phone: 24.0, smallPhone: 16.0, tablet: 32.0),
        ),
        TweenAnimationBuilder<double>(
          key: ValueKey('title_${data.titleKey}'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (_, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 16),
              child: child,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsive(phone: 380.0, tablet: 600.0),
            ),
            child: Text(
              data.titleKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        SizedBox(
          height: context.responsive(phone: 12.0, smallPhone: 8.0),
        ),
        TweenAnimationBuilder<double>(
          key: ValueKey('desc_${data.descKey}'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (_, value, child) =>
              Opacity(opacity: value, child: child),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsive(phone: 380.0, tablet: 600.0),
            ),
            child: Text(
              data.descKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: descSize,
                height: 1.6,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
