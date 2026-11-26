import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

const _trackHeight = 6.0;

/// Primary slider on the design track colour.
class AppSlider extends StatelessWidget {
  /// Creates the slider.
  const AppSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
    this.divisions,
    this.semanticsLabel,
    this.onChangeEnd,
  });

  /// Current value.
  final double value;

  /// Lowest value.
  final double min;

  /// Highest value.
  final double max;

  /// Number of steps, or null for continuous.
  final int? divisions;

  /// Called while dragging.
  final ValueChanged<double> onChanged;

  /// Called once with the final value when a drag or tap ends.
  final ValueChanged<double>? onChangeEnd;

  /// Screen reader label.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: _trackHeight,
        activeTrackColor: primary,
        inactiveTrackColor: context.appColors.track,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        showValueIndicator: ShowValueIndicator.never,
        padding: EdgeInsets.zero,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        semanticFormatterCallback: semanticsLabel == null
            ? null
            : (_) => semanticsLabel!,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
