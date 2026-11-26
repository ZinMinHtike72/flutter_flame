import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _growDuration = Duration(milliseconds: 700);
const _staggerStep = Duration(milliseconds: 70);
const _selectDuration = Duration(milliseconds: 260);
const _bubbleHeight = 18.0;
const _labelHeight = 16.0;
const _barRadius = 5.0;
const _barGap = 8.0;
const _pairGap = 3.0;
const _barMinFraction = 0.04;

/// Compact bar chart built from Flutter layout widgets. Bars grow in one
/// after another; the [selectedIndex] bar turns primary and shows
/// [valueLabel] just above it, the rest use the compare colour. Tapping a
/// bar calls [onSelected] with a selection haptic. Reduced motion skips the
/// growth.
class AppBarChart extends StatelessWidget {
  /// Creates the chart; [labels] must match [values] in length.
  const AppBarChart({
    required this.values,
    required this.labels,
    required this.valueLabel,
    super.key,
    this.selectedIndex,
    this.onSelected,
    this.height = 120,
    this.semanticsLabel,
    this.compareValues,
  }) : assert(values.length == labels.length),
       assert(compareValues == null || compareValues.length == values.length);

  /// Bar heights, any non-negative scale.
  final List<double> values;

  /// Short label under each bar.
  final List<String> labels;

  /// Text shown above the selected bar.
  final String Function(double value) valueLabel;

  /// Highlighted bar, or null for none.
  final int? selectedIndex;

  /// Called with a tapped bar's index; null makes the chart read-only.
  final ValueChanged<int>? onSelected;

  /// Total height including labels.
  final double height;

  /// Second series drawn beside each bar in the compare colour, such as
  /// last month. With it, bars show no selection.
  final List<double>? compareValues;

  /// Screen reader label for one bar; defaults to label and value.
  final String Function(int index)? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...values,
      ...?compareValues,
    ].fold<double>(0, (max, v) => v > max ? v : max);
    double fractionOf(double value) =>
        maxValue <= 0 ? 0 : (value / maxValue).clamp(_barMinFraction, 1);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < values.length; index++)
            Expanded(
              child: _Bar(
                fraction: fractionOf(values[index]),
                compareFraction: compareValues == null
                    ? null
                    : fractionOf(compareValues![index]),
                label: labels[index],
                bubble: valueLabel(values[index]),
                selected: index == selectedIndex,
                growDuration: reduceMotion
                    ? Duration.zero
                    : _growDuration + _staggerStep * index,
                selectDuration: reduceMotion ? Duration.zero : _selectDuration,
                semanticsLabel:
                    semanticsLabel?.call(index) ??
                    "${labels[index]}, ${valueLabel(values[index])}",
                onTap: onSelected == null
                    ? null
                    : () {
                        if (index != selectedIndex) {
                          HapticFeedback.selectionClick();
                        }
                        onSelected!(index);
                      },
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.label,
    required this.bubble,
    required this.selected,
    required this.growDuration,
    required this.selectDuration,
    required this.semanticsLabel,
    required this.onTap,
    this.compareFraction,
  });

  final double fraction;
  final double? compareFraction;
  final String label;
  final String bubble;
  final bool selected;
  final Duration growDuration;
  final Duration selectDuration;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _barGap / 2),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxBar = constraints.maxHeight - _bubbleHeight;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: growDuration,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: _bubbleHeight,
                            child: AnimatedOpacity(
                              opacity: selected ? 1 : 0,
                              duration: selectDuration,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FittedBox(
                                  child: Text(
                                    bubble,
                                    maxLines: 1,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colors.textStrong,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (compareFraction == null)
                            AnimatedContainer(
                              duration: selectDuration,
                              curve: Curves.easeOutCubic,
                              height: maxBar * value,
                              decoration: BoxDecoration(
                                color: selected ? primary : colors.compare,
                                borderRadius: BorderRadius.circular(_barRadius),
                              ),
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _Fill(
                                    height:
                                        maxBar *
                                        compareFraction! *
                                        (fraction == 0 ? 1 : value / fraction),
                                    color: colors.compare,
                                  ),
                                ),
                                const SizedBox(width: _pairGap),
                                Expanded(
                                  child: _Fill(
                                    height: maxBar * value,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              SizedBox(
                height: _labelHeight,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_barRadius - 2),
      ),
    ),
  );
}
