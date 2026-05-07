import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PremiumBadge extends StatelessWidget {
  final double size;
  const PremiumBadge({super.key, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size, vertical: size * 0.4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.lightTertiary, Color(0xFFE2C68C)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: size + 2, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'common.premium'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
