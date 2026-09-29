import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Intro animation shown at launch, then the sign-in page.
///
/// One continuous motion links the mark and the name:
/// 1. the white mark sits centered, exactly where the native splash left it;
/// 2. it glides to the start of the name while shrinking;
/// 3. it "writes" FAKARNI: it rides the left-to-right reveal edge while
///    dissolving into a small light dot that finishes the word;
/// 4. "فكرني" is revealed right-to-left (Arabic reading direction);
/// 5. after a short hold, the sign-in page opens. A tap anywhere skips.
///
/// The animation only starts once the fonts and the mark are loaded and the
/// first frame is on screen, so no step is skipped by start-up jank.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppDurations.onboardingIntro);

  late final Animation<double> _settle = _interval(0, 0.14, Curves.easeOut);
  late final Animation<double> _travel = _interval(0.14, 0.38, Curves.easeInOutCubic);
  late final Animation<double> _wipe = _interval(0.34, 0.66, Curves.easeInOutCubic);
  late final Animation<double> _markFade = _interval(0.36, 0.54, Curves.easeIn);
  late final Animation<double> _arabicWipe = _interval(0.62, 0.86, Curves.easeInOutCubic);

  Timer? _holdTimer;
  bool _started = false;
  bool _opened = false;

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _scheduleOpen();
    } else {
      _warmUpThenStart();
    }
  }

  Future<void> _warmUpThenStart() async {
    final ready = Future.wait<void>([
      precacheImage(const AssetImage(AppConstants.logoMarkAsset), context),
      GoogleFonts.pendingFonts([AppTypography.onboardingName, AppTypography.onboardingArabic]),
    ]);
    try {
      await ready.timeout(AppDurations.onboardingMaxWait);
    } catch (_) {
      // Offline first launch or slow device: animate with what is available.
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(AppDurations.onboardingStartDelay);
    if (!mounted) return;
    setState(() {}); // re-measure the name with the loaded fonts
    _controller.forward().whenComplete(_scheduleOpen);
  }

  void _scheduleOpen() => _holdTimer = Timer(AppDurations.onboardingHold, _openApp);

  void _openApp() {
    if (_opened || !mounted) return;
    _opened = true;
    context.go(AppRoutes.signIn);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Size of a text as it will be laid out on screen.
  Size _measure(String text, TextStyle style, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }

  @override
  Widget build(BuildContext context) {
    final name = _measure(AppConstants.brandName, AppTypography.onboardingName, TextDirection.ltr);
    final arabic = _measure(AppConstants.tagline, AppTypography.onboardingArabic, TextDirection.rtl);
    // Vertical center of the "FAKARNI" line relative to the screen center
    // (the two-line lockup is centered as a whole).
    final nameCenterY = -(AppSpacing.xs + arabic.height) / 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.brandDeep,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openApp,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final travel = _travel.value;
              final wipe = _wipe.value;
              final fade = _markFade.value;
              // Mark path: center → left edge of the name → along the reveal edge.
              final markX = lerpDouble(0, -name.width / 2, travel)! + name.width * wipe;
              final markY = lerpDouble(0, nameCenterY, travel)!;
              final markScale = (1 + 0.06 * _settle.value) * lerpDouble(1, 0.5, travel)! * lerpDouble(1, 0.6, fade)!;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WipeReveal(
                          progress: wipe,
                          fromLeft: true,
                          showDot: true,
                          child: Text(AppConstants.brandName, style: AppTypography.onboardingName),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Opacity(
                          opacity: _arabicWipe.value,
                          child: _WipeReveal(
                            progress: _arabicWipe.value,
                            fromLeft: false,
                            child: Text(
                              AppConstants.tagline,
                              textDirection: TextDirection.rtl,
                              style: AppTypography.onboardingArabic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Drawn above the name: it leads the reveal before dissolving.
                  Center(
                    child: Opacity(
                      opacity: (1 - fade).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(markX, markY),
                        child: Transform.scale(
                          scale: markScale,
                          child: Image.asset(
                            AppConstants.logoMarkAsset,
                            width: AppSizes.onboardingMarkWidth,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Reveals [child] with a hard-edged wipe; layout size never changes, so the
/// text stays perfectly centered while it appears.
class _WipeReveal extends StatelessWidget {
  const _WipeReveal({required this.progress, required this.fromLeft, required this.child, this.showDot = false});

  final double progress;
  final bool fromLeft;
  final bool showDot;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clipped = ClipRect(clipper: _WipeClipper(progress, fromLeft), child: child);
    if (!showDot) return clipped;
    return CustomPaint(foregroundPainter: _LeadingDotPainter(progress), child: clipped);
  }
}

class _WipeClipper extends CustomClipper<Rect> {
  _WipeClipper(this.progress, this.fromLeft);

  final double progress;
  final bool fromLeft;

  @override
  Rect getClip(Size size) {
    // Extra vertical room so accents and Arabic marks are never cut.
    final top = -size.height;
    final bottom = size.height * 2;
    return fromLeft
        ? Rect.fromLTRB(0, top, size.width * progress, bottom)
        : Rect.fromLTRB(size.width * (1 - progress), top, size.width, bottom);
  }

  @override
  bool shouldReclip(covariant _WipeClipper old) => old.progress != progress || old.fromLeft != fromLeft;
}

/// Small glowing dot riding the wipe edge; it takes over from the dissolving
/// mark and fades out as the word completes.
class _LeadingDotPainter extends CustomPainter {
  _LeadingDotPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final strength = math.sin(math.pi * progress);
    final center = Offset(size.width * progress + AppSizes.onboardingDot, size.height * 0.22);
    const radius = AppSizes.onboardingDot / 2;
    canvas.drawCircle(
      center,
      radius * 2.2,
      Paint()
        ..color = AppColors.glowWhite.withValues(alpha: 0.6 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, radius * 1.6),
    );
    canvas.drawCircle(center, radius, Paint()..color = AppColors.white.withValues(alpha: strength));
  }

  @override
  bool shouldRepaint(covariant _LeadingDotPainter old) => old.progress != progress;
}
