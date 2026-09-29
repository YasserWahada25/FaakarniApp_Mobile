import 'package:flutter/material.dart';

import 'state_views.dart';

/// Status of a screen whose data comes from the API.
enum ViewStatus { loading, ready, error }

/// Switches between the loading, error, empty and content states of a
/// data-driven section, so every screen renders them the same way.
class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.status,
    required this.isEmpty,
    required this.builder,
    required this.empty,
    this.errorMessage,
    this.onRetry,
    this.loading,
  });

  final ViewStatus status;
  final bool isEmpty;
  final WidgetBuilder builder;
  final Widget empty;
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// Defaults to a skeleton list.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (status) {
      ViewStatus.loading => loading ?? const SkeletonList(),
      ViewStatus.error => ErrorStateView(message: errorMessage, onRetry: onRetry),
      ViewStatus.ready when isEmpty => empty,
      ViewStatus.ready => builder(context),
    };
    return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child);
  }
}
