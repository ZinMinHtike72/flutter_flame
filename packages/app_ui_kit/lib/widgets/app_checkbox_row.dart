import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _boxSize = 20.0;

/// Small checkbox with a label; the whole row toggles.
class AppCheckboxRow extends StatelessWidget {
  /// Creates the row.
  const AppCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Text.
  final String label;

  /// Checked.
  final bool value;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            SizedBox.square(
              dimension: _boxSize,
              child: Checkbox(
                value: value,
                onChanged: (checked) => onChanged(checked ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
