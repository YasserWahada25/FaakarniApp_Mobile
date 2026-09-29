import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Navbar logo: image + "FAKARNI" + Arabic tagline (web `.logo`).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = AppSizes.logoHeight, this.showText = true, this.onDark = false});

  final double height;
  final bool showText;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: AppRadius.smAll,
          child: Image.asset(AppConstants.logoAsset, height: height, fit: BoxFit.contain),
        ),
        if (showText) ...[
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.brandName,
                style: AppTypography.brandName.copyWith(color: onDark ? AppColors.white : null, height: 1.1),
              ),
              Text(
                AppConstants.tagline,
                style: AppTypography.tagline.copyWith(color: onDark ? AppColors.primaryLight : null, height: 1.2),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
