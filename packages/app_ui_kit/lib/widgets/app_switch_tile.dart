import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

/// Native switch tile retaining platform semantics and keyboard interaction.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.icon,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: colors.onPrimary,
      activeTrackColor: colors.primary,
      inactiveThumbColor: colors.onSurfaceVariant,
      inactiveTrackColor: colors.onSurface.withValues(alpha: 0.06),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.primary
            : colors.onSurface.withValues(alpha: 0.16),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
      secondary: icon == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, size: AppSpacing.lg, color: colors.primary),
              ),
            ),
    );
  }
}
