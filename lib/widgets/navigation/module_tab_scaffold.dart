import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

class ModuleTab {
  const ModuleTab({required this.label, required this.icon, required this.body});

  final String label;
  final IconData icon;
  final Widget body;
}

/// Module screen with a [TabBar] under the app bar. It replaces the web
/// module sidebars (Alzheimer Care, Geofencing, Education, …).
///
/// [initialIndex] comes from the `?tab=` route parameter; when it changes
/// while the screen is shown (drawer navigation) the tab animates to it.
class ModuleTabScaffold extends StatefulWidget {
  const ModuleTabScaffold({
    super.key,
    required this.title,
    required this.tabs,
    this.initialIndex = 0,
    this.accentColor = AppColors.primaryDark,
    this.showDrawerButton = true,
    this.actions,
    this.floatingActionButtonBuilder,
  });

  final String title;
  final List<ModuleTab> tabs;
  final int initialIndex;
  final Color accentColor;

  /// `true` inside the bottom-navigation shell (menu button opens the drawer),
  /// `false` for full-screen modules (back button).
  final bool showDrawerButton;
  final List<Widget>? actions;

  /// Optional FAB depending on the selected tab.
  final Widget? Function(int index)? floatingActionButtonBuilder;

  @override
  State<ModuleTabScaffold> createState() => _ModuleTabScaffoldState();
}

class _ModuleTabScaffoldState extends State<ModuleTabScaffold> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.initialIndex.clamp(0, widget.tabs.length - 1),
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (!_controller.indexIsChanging) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ModuleTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _controller.animateTo(widget.initialIndex.clamp(0, widget.tabs.length - 1));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // `context` is above this Scaffold, so it resolves to the shell's
        // Scaffold, which owns the drawer.
        leading: widget.showDrawerButton
            ? IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : const BackButton(),
        title: Text(widget.title, style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(color: widget.accentColor)),
        actions: widget.actions,
        bottom: TabBar(
          controller: _controller,
          isScrollable: widget.tabs.length > 3,
          tabAlignment: widget.tabs.length > 3 ? TabAlignment.start : TabAlignment.fill,
          labelColor: widget.accentColor,
          indicatorColor: widget.accentColor,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tabs: [
            for (final tab in widget.tabs)
              Tab(
                height: AppSizes.minTouchTarget + AppSpacing.xs,
                iconMargin: const EdgeInsets.only(bottom: AppSpacing.xxs),
                icon: Icon(tab.icon, size: AppSizes.iconMd),
                text: tab.label,
              ),
          ],
        ),
      ),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(_controller.index),
      body: TabBarView(
        controller: _controller,
        children: [for (final tab in widget.tabs) tab.body],
      ),
    );
  }
}
