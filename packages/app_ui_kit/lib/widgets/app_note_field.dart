import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

/// Multiline evidence input that restores its initial BLoC value after refresh.
class AppNoteField extends StatelessWidget {
  const AppNoteField({
    required this.initialValue,
    required this.labelText,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.maxLength = 2000,
  });
  final String initialValue;
  final String labelText;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int maxLength;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.12)),
    );
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLength: maxLength,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        counterStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        alignLabelWithHint: true,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
