import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _trackRadius = 14.0;
const _thumbRadius = 10.0;
const _duration = Duration(milliseconds: 260);

/// Equal-width options on a tinted track; the selected one sits on a card
/// thumb that slides between them.
class AppSegmentedControl extends StatelessWidget {
  /// Creates the control.
  const AppSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(labels.length > 1);

  /// Option labels.
  final List<String> labels;

  /// Selected option.
  final int selectedIndex;

  /// Called with a tapped option.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final light = theme.brightness == Brightness.light;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duration;
    final count = labels.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: BorderRadius.circular(_trackRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                  count == 1 ? 0 : -1 + 2 * selectedIndex / (count - 1),
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(_thumbRadius),
                      boxShadow: light
                          ? [
                              BoxShadow(
                                color: colors.cardShadow,
                                blurRadius: AppSpacing.sm,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == selectedIndex,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i != selectedIndex) {
                            HapticFeedback.selectionClick();
                          }
                          onSelected(i);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: i == selectedIndex
                                  ? colors.textStrong
                                  : colors.textMuted,
                              fontWeight: i == selectedIndex
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            child: Text(labels[i], maxLines: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
