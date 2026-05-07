import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../app/providers.dart';
import '../../../config/env.dart';
import '../../../core/extensions/extensions.dart';
import '../../viewmodels/subscription_viewmodel.dart';

/// Native ad styled to look like a note card. Falls back to SizedBox if not loaded.
class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
  }

  void _maybeLoad() {
    if (!mounted) return;
    final isPremium = ref.read(subscriptionViewModelProvider).isPremium;
    if (isPremium || !Env.adsEnabled) return;
    final ad = ref.read(adsServiceProvider).buildNativeAd(
      onLoaded: (_) {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: (_) {
        if (mounted) setState(() => _loaded = false);
      },
    );
    _ad = ad;
    try {
      ad.load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AdWidget(ad: _ad!),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backwards-compatible alias — banner is no longer used; renders nothing.
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
