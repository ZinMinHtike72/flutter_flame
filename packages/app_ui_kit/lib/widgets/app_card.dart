import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";

const _radius = 20.0;
const _shadowBlur = 24.0;
const _shadowOffset = 8.0;
const _hairlineBlur = 2.0;

/// White content card: 20 radius, hairline border and a soft brand shadow
/// (none in dark mode). An optional header shows [title] with a small
/// primary [action] text at the end. [onTap] makes the whole card pressable.
class AppCard extends StatelessWidget {
  /// Creates the card.
  const AppCard({
    required this.child,
    super.key,
    this.title,
    this.action,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  /// Card content under the header.
  final Widget child;

  /// Header title.
  final String? title;

  /// Small primary text at the end of the header, such as "See all ›".
  final String? action;

  /// Makes the card a button.
  final VoidCallback? onTap;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final light = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(_radius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: radius,
        border: Border.all(color: colors.line),
        boxShadow: light
            ? [
                BoxShadow(
                  color: colors.textStrong.withValues(alpha: 0.05),
                  blurRadius: _hairlineBlur,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: colors.cardShadow,
                  blurRadius: _shadowBlur,
                  offset: const Offset(0, _shadowOffset),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textStrong,
                      ),
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      action!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ],
            child,
          ],
        ),
      ),
    );
    if (onTap == null) {
      return card;
    }
    return Semantics(
      button: true,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}
