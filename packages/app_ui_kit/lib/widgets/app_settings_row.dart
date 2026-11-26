import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";

const _rowMinimumHeight = 72.0;

/// A flexible, accessible action row for preferences and account actions.
class AppSettingsRow extends StatelessWidget {
  const AppSettingsRow({
    required this.title,
    required this.icon,
    required this.onPressed,
    super.key,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    this.selected,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? subtitle;
  final Widget? trailing;
  final bool destructive;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = destructive ? colors.error : colors.primary;
    final radius = BorderRadius.circular(AppSpacing.md);
    return AppPressable(
      enabled: onPressed != null,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        selected: selected,
        inMutuallyExclusiveGroup: selected != null,
        child: Material(
          color: selected == true
              ? accent.withValues(alpha: 0.06)
              : colors.surface.withValues(alpha: 0),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowMinimumHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Icon(icon, color: accent, size: AppSpacing.lg),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: destructive
                                  ? colors.error
                                  : colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
