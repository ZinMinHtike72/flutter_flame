import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";

/// A tactile source/action choice with an accessible full-row target.
class AppActionTile extends StatelessWidget {
  const AppActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
    this.highlighted = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppSurface(
      onTap: onPressed,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: highlighted
              ? LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.07),
                    colors.primary.withValues(alpha: 0.01),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: highlighted
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Icon(
                    icon,
                    size: AppSpacing.lg,
                    color: highlighted ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(AppIcons.chevron, size: 18, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
