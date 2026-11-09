import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_dimens.dart';
import '../../providers/auth_provider.dart';
import '../common/app_logo.dart';
import '../common/dialogs.dart';

class _DrawerLink {
  const _DrawerLink(this.label, this.location, {this.push = false});

  final String label;
  final String location;

  /// `true` for full-screen routes (outside the bottom-navigation shell).
  final bool push;
}

class _DrawerSection {
  const _DrawerSection(this.label, this.icon, this.links);

  final String label;
  final IconData icon;
  final List<_DrawerLink> links;
}

/// Full navigation tree: the mobile version of the web navbar and its
/// dropdown menus (HOME, ALZHEIMER, GEOFENCING, …, POSTS, CONTACT).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static final List<_DrawerSection> _sections = [
    _DrawerSection('ALZHEIMER', Icons.psychology_alt_outlined, [
      _DrawerLink('Calendar', AppRoutes.withTab(AppRoutes.alzheimer, 'consultation')),
      _DrawerLink('Réservations', AppRoutes.withTab(AppRoutes.alzheimer, 'reservations')),
      _DrawerLink('Favorites', AppRoutes.withTab(AppRoutes.alzheimer, 'favorites')),
      _DrawerLink('Reports', AppRoutes.withTab(AppRoutes.alzheimer, 'reports')),
      _DrawerLink('Notifications', AppRoutes.withTab(AppRoutes.alzheimer, 'notifications')),
    ]),
    _DrawerSection('GEOFENCING', Icons.map_outlined, [
      _DrawerLink('Live Tracking', AppRoutes.withTab(AppRoutes.geofencing, 'tracking')),
      _DrawerLink('Alert & History', AppRoutes.withTab(AppRoutes.geofencing, 'alerts')),
      _DrawerLink('Supervision & Stats', AppRoutes.withTab(AppRoutes.geofencing, 'supervision')),
    ]),
    _DrawerSection('EDUCATIONAL', Icons.school_outlined, [
      _DrawerLink('Activities & Content', AppRoutes.withTab(AppRoutes.educational, 'activities')),
      _DrawerLink('Events & Calendar', AppRoutes.withTab(AppRoutes.educational, 'events')),
      _DrawerLink('Progress Tracking', AppRoutes.withTab(AppRoutes.educational, 'tracking')),
    ]),
    _DrawerSection('COMMUNICATION', Icons.forum_outlined, [
      _DrawerLink('Messaging & Feed', AppRoutes.withTab(AppRoutes.communication, 'messaging')),
      _DrawerLink('Groups & Support', AppRoutes.withTab(AppRoutes.communication, 'groups')),
    ]),
    _DrawerSection('MEDICAL FOLLOW-UP', Icons.medical_services_outlined, [
      _DrawerLink('Disease Detection', AppRoutes.withTab(AppRoutes.medical, 'detection'), push: true),
      _DrawerLink('Medical Records', AppRoutes.withTab(AppRoutes.medical, 'records'), push: true),
      _DrawerLink('Follow-up', AppRoutes.withTab(AppRoutes.medical, 'follow-up'), push: true),
    ]),
    _DrawerSection('POSTS', Icons.dynamic_feed_outlined, [
      _DrawerLink('Community Posts', AppRoutes.home),
      _DrawerLink('My Posts', AppRoutes.myPosts, push: true),
      _DrawerLink('Create Post', AppRoutes.postCreate, push: true),
    ]),
  ];

  void _open(BuildContext context, _DrawerLink link) {
    Navigator.of(context).pop();
    link.push ? context.push(link.location) : context.go(link.location);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppGradients.brand),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(height: AppSizes.logoMd, onDark: true),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Seniors deserve a better life',
                      style: text.bodySmall?.copyWith(color: AppColors.primaryLight),
                    ),
                    if (AuthProvider.instance.user case final user?) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(user.fullName, style: text.titleSmall?.copyWith(color: AppColors.white)),
                      Text(
                        '${user.role.label} · ${user.email}',
                        style: text.bodySmall?.copyWith(color: AppColors.primaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('HOME'),
                  onTap: () => _open(context, const _DrawerLink('HOME', AppRoutes.home)),
                ),
                for (final section in _sections)
                  ExpansionTile(
                    leading: Icon(section.icon, color: AppColors.primaryDark),
                    title: Text(section.label, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    childrenPadding: const EdgeInsets.only(left: AppSpacing.xxxl),
                    children: [
                      for (final link in section.links)
                        ListTile(
                          dense: true,
                          title: Text(link.label),
                          trailing: const Icon(Icons.chevron_right_rounded, size: AppSizes.iconMd),
                          onTap: () => _open(context, link),
                        ),
                    ],
                  ),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('CONTACT'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showContactSheet(context);
                  },
                ),
                const Divider(height: AppSpacing.xxl),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Edit profile'),
                  onTap: () => _open(context, const _DrawerLink('Profile', AppRoutes.profile, push: true)),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text('Logout', style: text.bodyLarge?.copyWith(color: AppColors.error)),
                  onTap: () {
                    Navigator.of(context).pop();
                    // The router sends the signed-out user back to the sign-in page.
                    AuthProvider.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
