import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";

/// A radio-like preference tile with a softly animated selected surface.
class AppChoiceTile extends StatelessWidget {
  const AppChoiceTile({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
    this.icon,
    this.subtitle,
  });
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppSpacing.md);
    return AppPressable(
      enabled: onPressed != null,
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        enabled: onPressed != null,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.onSurface.withValues(alpha: 0.025),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 76),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: selected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected ? colors.primary : colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
