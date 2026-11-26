import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// A text field using the application's shared input decoration theme.
class AppTextField extends StatelessWidget {
  /// Creates a field; presentation strings are supplied by the caller.
  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.autofillHints,
    this.useSoftDecoration = false,
    this.reserveErrorSpace = false,
    this.inputFormatters,
  });

  /// The caller-owned editing controller.
  final TextEditingController? controller;

  /// Localized label supplied by the caller.
  final String? labelText;

  /// Localized hint supplied by the caller.
  final String? hintText;

  /// Localized error message supplied by the caller.
  final String? errorText;

  /// Keyboard layout for this input.
  final TextInputType? keyboardType;

  /// Automatic capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Whether to hide the entered text.
  final bool obscureText;

  /// Receives editing changes without maintaining local widget state.
  final ValueChanged<String>? onChanged;

  /// Whether the field accepts input.
  final bool enabled;

  /// The caller-owned focus node.
  final FocusNode? focusNode;

  /// Action displayed on the software keyboard.
  final TextInputAction? textInputAction;

  /// Receives submission from the software keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Maximum visible lines; null allows unbounded lines.
  final int? maxLines;

  /// Leading content, supplied by the caller.
  final Widget? prefixIcon;

  /// Trailing content, such as a localized visibility action.
  final Widget? suffixIcon;

  /// Platform autofill suggestions for this input.
  final Iterable<String>? autofillHints;

  /// Uses a rounded, lightly tinted surface for prominent credential forms.
  final bool useSoftDecoration;

  /// Keeps the error line's space when there is no error, so showing one
  /// does not change the field's height.
  final bool reserveErrorSpace;

  /// Restricts or reshapes what the user can type.
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final softBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.10)),
    );
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        helperText: reserveErrorSpace && errorText == null ? " " : null,
        errorMaxLines: reserveErrorSpace ? 1 : null,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: useSoftDecoration ? true : null,
        fillColor: useSoftDecoration
            ? colors.onSurface.withValues(alpha: 0.025)
            : null,
        contentPadding: useSoftDecoration
            ? const EdgeInsets.all(AppSpacing.md + AppSpacing.xs)
            : null,
        enabledBorder: useSoftDecoration ? softBorder : null,
        disabledBorder: useSoftDecoration ? softBorder : null,
        focusedBorder: useSoftDecoration
            ? softBorder.copyWith(
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              )
            : null,
        errorBorder: useSoftDecoration
            ? softBorder.copyWith(borderSide: BorderSide(color: colors.error))
            : null,
        focusedErrorBorder: useSoftDecoration
            ? softBorder.copyWith(
                borderSide: BorderSide(color: colors.error, width: 1.5),
              )
            : null,
        floatingLabelStyle: useSoftDecoration
            ? Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: colors.primary)
            : null,
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      onChanged: onChanged,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
    );
  }
}
