import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Round avatar showing initials, or an icon when no initials are given.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    this.initials,
    this.icon = Icons.person_rounded,
    this.size = AppSizes.avatar,
    this.color = AppColors.primary,
    this.statusColor,
  });

  final String? initials;
  final IconData icon;
  final double size;
  final Color color;

  /// Presence dot (online / away / offline).
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: initials == null || initials!.isEmpty
          ? Icon(icon, color: color, size: size * 0.5)
          : Text(
              initials!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontSize: size * 0.34),
            ),
    );
    if (statusColor == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
