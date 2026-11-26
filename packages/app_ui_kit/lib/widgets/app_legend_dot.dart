import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _swatch = 10.0;
const _swatchRadius = 3.0;

/// Chart legend entry: a small rounded colour swatch and a label.
class AppLegendDot extends StatelessWidget {
  /// Creates the entry.
  const AppLegendDot({required this.color, required this.label, super.key});

  /// Series colour.
  final Color color;

  /// Series name.
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_swatchRadius),
        ),
        child: const SizedBox.square(dimension: _swatch),
      ),
      const SizedBox(width: AppSpacing.xs + 1),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.appColors.textMuted),
      ),
    ],
  );
}
