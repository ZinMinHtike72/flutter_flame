import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _width = 52.0;
const _radius = 16.0;
const _duration = Duration(milliseconds: 220);

/// Day picker chip: short weekday over the day number, centred in the chip
/// however tall it is made; filled with the primary colour when selected.
class AppDateChip extends StatelessWidget {
  /// Creates the chip.
  const AppDateChip({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
    super.key,
    this.semanticsLabel,
  });

  /// Short weekday, such as "Fri".
  final String weekday;

  /// Day of the month, such as "13".
  final String day;

  /// Whether this is the picked day.
  final bool selected;

  /// Picks the day.
  final VoidCallback onTap;

  /// Full date for screen readers.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duration;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? "$weekday $day",
      excludeSemantics: true,
      child: AppPressable(
        child: GestureDetector(
          onTap: () {
            if (!selected) {
              HapticFeedback.selectionClick();
            }
            onTap();
          },
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: _width,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? primary : colors.card,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: selected ? primary : colors.line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekday,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? onPrimary.withValues(alpha: 0.85)
                        : colors.textMuted,
                  ),
                ),
                Text(
                  day,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? onPrimary : colors.textStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
