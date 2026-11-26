import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _rowPadding = 6.0;
const _totalPadding = 10.0;

/// One line of a worked calculation: muted label, value at the end. A
/// [total] line sits under a hairline and is bold.
class AppCalcLine extends StatelessWidget {
  /// Creates the line.
  const AppCalcLine({
    required this.label,
    required this.value,
    super.key,
    this.total = false,
    this.strongValue = false,
  });

  /// Left text.
  final String label;

  /// Right text.
  final String value;

  /// True for the result line.
  final bool total;

  /// Bold value on a normal line.
  final bool strongValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final base = total ? theme.textTheme.bodyLarge : theme.textTheme.bodyMedium;
    final row = Padding(
      padding: EdgeInsets.only(
        top: total ? _totalPadding : _rowPadding,
        bottom: _rowPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: base?.copyWith(
                color: total ? colors.textStrong : colors.textMuted,
                fontWeight: total ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: base?.copyWith(
              color: colors.textStrong,
              fontWeight: total || strongValue
                  ? FontWeight.w600
                  : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    if (!total) {
      return row;
    }
    return Padding(
      padding: const EdgeInsets.only(top: _rowPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: row,
      ),
    );
  }
}
