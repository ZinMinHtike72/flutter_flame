import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";

/// Reusable tactile surface shared across feature screens.
class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    super.key,
    this.onTap,
    this.accent = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool accent;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppPressable(
      enabled: onTap != null,
      child: Material(
        color: accent ? colors.primaryContainer : colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          side: BorderSide(
            color: accent
                ? colors.primary.withValues(alpha: 0.2)
                : colors.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppFilterPill extends StatelessWidget {
  const AppFilterPill({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.detail,
    this.trailingIcon,
    this.tooltip,
  });
  final String label;
  final String? detail;
  final IconData? trailingIcon;
  final String? tooltip;
  final bool selected;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    backgroundColor: Theme.of(context).colorScheme.surface,
    selectedColor: Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.12),
    side: BorderSide(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
    ),
    labelStyle: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    tooltip: tooltip,
    label: trailingIcon == null && detail == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (detail != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  detail!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  trailingIcon,
                  size: AppSpacing.md,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
    selected: selected,
    onSelected: (_) => onSelected(),
    showCheckmark: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.lg),
    ),
  );
}

class AppRefreshScroll extends StatelessWidget {
  const AppRefreshScroll({
    required this.slivers,
    required this.onRefresh,
    super.key,
    this.edgeOffset = 0,
  });
  final List<Widget> slivers;
  final Future<void> Function() onRefresh;

  /// Distance from the top where the refresh spinner appears, such as
  /// below a pinned app bar.
  final double edgeOffset;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    edgeOffset: edgeOffset,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    ),
  );
}

enum AppStatusTone { neutral, completed, pending, inProgress, critical }

class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    required this.label,
    super.key,
    this.emphasized = false,
    this.tone = AppStatusTone.neutral,
  });
  final String label;
  final bool emphasized;
  final AppStatusTone tone;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = switch (tone) {
      AppStatusTone.neutral => null,
      AppStatusTone.completed => context.appColors.statusCompleted,
      AppStatusTone.pending => context.appColors.statusPending,
      AppStatusTone.inProgress => context.appColors.statusInProgress,
      AppStatusTone.critical => colors.error,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            accent?.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.16
                  : 0.10,
            ) ??
            (emphasized
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.045)),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:
                accent ??
                (emphasized ? colors.onPrimary : colors.onSurfaceVariant),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Native back handling protects an in-flight submission.
class AppProtectedRoute extends StatelessWidget {
  const AppProtectedRoute({
    required this.canPop,
    required this.child,
    this.onBackAttempted,
    super.key,
  });
  final bool canPop;
  final VoidCallback? onBackAttempted;
  final Widget child;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: canPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        onBackAttempted?.call();
      }
    },
    child: child,
  );
}
