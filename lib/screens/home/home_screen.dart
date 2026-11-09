import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_images.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/network_picture.dart';

/// Web `/home`: hero, "About us" services, 3-step process and footer, plus
/// a quick-access grid replacing the web navbar dropdowns.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _servicesKey = GlobalKey();

  void _scrollToServices() {
    final ctx = _servicesKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: AppDurations.slow, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        titleSpacing: 0,
        title: const AppLogo(height: AppSizes.logoSm),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => context.push(AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            // The router sends the signed-out user back to the sign-in page.
            onPressed: AuthProvider.instance.signOut,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(onLearnMore: _scrollToServices),
          const _QuickAccess(),
          _Services(key: _servicesKey),
          const _Process(),
          const _Footer(),
        ],
      ),
    );
  }
}

/// Fade + slide-up entrance (web `@fadeInUp`).
class _FadeInUp extends StatelessWidget {
  const _FadeInUp({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow + Duration(milliseconds: delay),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = AppTypography.heroTitle;
    return Stack(
      children: [
        const Positioned.fill(child: NetworkPicture(url: AppImages.hero)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.white.withValues(alpha: 0.97), AppColors.bgMain.withValues(alpha: 0.82)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxxl, AppSpacing.gutter, AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FadeInUp(
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) const Icon(Icons.add, size: AppSizes.iconSm - 4, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text('RAISE YOUR VOICE TO WIN', style: AppTypography.eyebrow, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FadeInUp(
                delay: 100,
                child: Text.rich(
                  TextSpan(
                    style: title,
                    children: [
                      const TextSpan(text: 'Seniors Deserve\n'),
                      TextSpan(
                        text: 'Better Life',
                        style: title.copyWith(
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 1.5
                            ..color = AppColors.primary,
                        ),
                      ),
                      const TextSpan(text: ' Taking\nCare Relatives '),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.star_rounded, color: AppColors.primary, size: AppSizes.iconLg),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _FadeInUp(
                delay: 200,
                child: Text(
                  'We collaborate, we think, we create outside the box.',
                  style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _FadeInUp(
                delay: 300,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: AppRadius.pillAll,
                          boxShadow: AppShadows.md,
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                          ),
                          onPressed: onLearnMore,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          iconAlignment: IconAlignment.end,
                          label: const Text('LEARN MORE'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const _HeroBadge(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.heroBadge,
      height: AppSizes.heroBadge,
      decoration: const BoxDecoration(gradient: AppGradients.badge, shape: BoxShape.circle, boxShadow: AppShadows.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MEDICAL\nSUPPORT',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white, height: 1.2),
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Icon(Icons.monitor_heart_outlined, color: AppColors.white, size: AppSizes.icon),
        ],
      ),
    );
  }
}

class _QuickAccessItem {
  const _QuickAccessItem(this.label, this.icon, this.location, {this.push = false});

  final String label;
  final IconData icon;
  final String location;
  final bool push;
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  static const List<_QuickAccessItem> _items = [
    _QuickAccessItem('Alzheimer', Icons.psychology_alt_outlined, AppRoutes.alzheimer),
    _QuickAccessItem('Geofencing', Icons.map_outlined, AppRoutes.geofencing),
    _QuickAccessItem('Educational', Icons.school_outlined, AppRoutes.educational),
    _QuickAccessItem('Communication', Icons.forum_outlined, AppRoutes.communication),
    _QuickAccessItem('Medical', Icons.medical_services_outlined, AppRoutes.medical, push: true),
    _QuickAccessItem('Posts', Icons.dynamic_feed_outlined, AppRoutes.posts, push: true),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl, AppSpacing.gutter, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick access', style: text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.05,
            children: [
              for (final item in _items)
                Material(
                  color: AppColors.white,
                  borderRadius: AppRadius.lgAll,
                  child: InkWell(
                    borderRadius: AppRadius.lgAll,
                    onTap: () => item.push ? context.push(item.location) : context.go(item.location),
                    child: Ink(
                      decoration: AppDecorations.card(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm + 2),
                            decoration: const BoxDecoration(color: AppColors.bgMain, shape: BoxShape.circle),
                            child: Icon(item.icon, color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(item.label, style: text.labelMedium?.copyWith(color: AppColors.primaryDark)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Services extends StatelessWidget {
  const _Services({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.softVertical),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: AppSizes.collageHeight,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  right: 70,
                  bottom: 40,
                  child: NetworkPicture(
                    url: AppImages.serviceMain,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.organic), bottomRight: Radius.circular(AppRadius.organic)),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle, boxShadow: AppShadows.md),
                    child: const NetworkPicture(
                      url: AppImages.serviceIcon,
                      width: AppSizes.collageAvatar,
                      height: AppSizes.collageAvatar,
                      borderRadius: BorderRadius.all(Radius.circular(AppRadius.round)),
                    ),
                  ),
                ),
                const Positioned(
                  right: 10,
                  bottom: 0,
                  width: AppSizes.collageSubWidth,
                  height: AppSizes.collageSubHeight,
                  child: NetworkPicture(
                    url: AppImages.serviceSub,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(AppRadius.organic), bottomLeft: Radius.circular(AppRadius.organic)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              const Icon(Icons.add, size: AppSizes.iconSm, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('ABOUT US', style: AppTypography.eyebrow),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('We Believe We Can Save More Lives', style: text.displaySmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            'At our senior care center, we believe we can save more lives—not just through advanced medical support, '
            'but through early intervention, daily monitoring, and heartfelt human connection.',
            style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(child: _ServiceCard(icon: Icons.volunteer_activism_outlined, label: 'Personalized Care Service')),
              SizedBox(width: AppSpacing.md),
              Expanded(child: _ServiceCard(icon: Icons.medical_services_outlined, label: 'Complete Medical Supply')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final item in const [
            'Compassionate Eldercare Solutions',
            'Everlasting Comfort Eldercare',
            'Serenity at Home Senior Services',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => showContactSheet(context),
            icon: const Icon(Icons.arrow_right_alt_rounded),
            iconAlignment: IconAlignment.end,
            label: const Text('DISCOVER MORE'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: AppSizes.iconLg + 4),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _Process extends StatelessWidget {
  const _Process();

  static const List<(String, String, String, String)> _steps = [
    ('01', 'Make An Enquiry', "Feel free to reach out and make an enquiry. We're here to assist you.", AppImages.step1),
    ('02', 'Create A NDIS Plan', "Let's craft a personalized NDIS plan to address your specific needs.", AppImages.step2),
    ('03', 'Start Exceptional Care', 'Start your journey with us, where we prioritize your exceptional care.', AppImages.step3),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.authBackground),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.section),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: AppDecorations.pill(AppColors.white, border: AppColors.primary),
            child: Text('OUR WORKING PROCESS', style: AppTypography.eyebrowSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              text: 'Get Started In Just ',
              children: [
                TextSpan(
                  text: '3 Steps',
                  style: text.displaySmall?.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryLight,
                    decorationThickness: 4,
                  ),
                ),
              ],
            ),
            style: text.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          for (var i = 0; i < _steps.length; i++) ...[
            _StepCard(number: _steps[i].$1, title: _steps[i].$2, body: _steps[i].$3, image: _steps[i].$4),
            if (i < _steps.length - 1)
              const SizedBox(
                height: AppSpacing.xxxl,
                child: VerticalDivider(color: AppColors.primary, thickness: 2, width: 2),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.title, required this.body, required this.image});

  final String number;
  final String title;
  final String body;
  final String image;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            NetworkPicture(url: image, height: AppSizes.stepImageHeight, width: double.infinity, borderRadius: AppRadius.pillAll),
            Positioned(
              right: AppSpacing.lg,
              bottom: -22,
              child: Container(
                width: AppSizes.avatarLg - 12,
                height: AppSizes.avatarLg - 12,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: AppGradients.primary, shape: BoxShape.circle, boxShadow: AppShadows.md),
                child: Text(number, style: text.titleMedium?.copyWith(color: AppColors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: AppColors.primaryLight);
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.brand),
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxxl, AppSpacing.gutter, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(onDark: true),
          const SizedBox(height: AppSpacing.md),
          Text(AppConstants.footerDescription, style: muted),
          const SizedBox(height: AppSpacing.xl),
          Text('Contact Us', style: text.titleMedium?.copyWith(color: AppColors.white)),
          const SizedBox(height: AppSpacing.sm),
          for (final (icon, label) in const [
            (Icons.location_on_outlined, AppConstants.contactAddress),
            (Icons.phone_outlined, AppConstants.contactPhone),
            (Icons.mail_outline_rounded, AppConstants.contactEmail),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primaryLight, size: AppSizes.iconMd),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(label, style: muted)),
                ],
              ),
            ),
          const Divider(color: AppColors.primaryDark, height: AppSpacing.xxxl),
          Center(child: Text('© ${DateTime.now().year} Fakarni. All Rights Reserved.', style: text.bodySmall?.copyWith(color: AppColors.primaryLight))),
        ],
      ),
    );
  }
}
