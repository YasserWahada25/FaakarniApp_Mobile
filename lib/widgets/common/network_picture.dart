import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import 'shimmer.dart';

/// Network image with a shimmer while loading and a soft placeholder on error.
class NetworkPicture extends StatelessWidget {
  const NetworkPicture({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Shimmer(child: SkeletonBox(height: height ?? AppSizes.thumbHeight, width: width ?? double.infinity, radius: 0)),
        errorBuilder: (context, error, stack) => Container(
          height: height,
          width: width,
          color: AppColors.bgSecondary,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, color: AppColors.primarySoft, size: AppSizes.iconLg),
        ),
      ),
    );
  }
}
