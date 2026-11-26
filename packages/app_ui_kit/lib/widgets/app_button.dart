import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_gradient_button.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";

/// The application's elevated button, styled entirely by its theme.
class AppElevatedButton extends StatelessWidget {
  /// Creates a button; null [onPressed] disables it.
  const AppElevatedButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  /// Action to perform when pressed.
  final VoidCallback? onPressed;

  /// Caller-supplied button content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      enabled: onPressed != null,
      child: ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}

/// Secondary action matching [AppGradientButton]: same height, radius, type
/// and press feedback.
class AppOutlinedButton extends StatelessWidget {
  /// Creates a button; null [onPressed] disables it.
  const AppOutlinedButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  /// Action to perform when pressed.
  final VoidCallback? onPressed;

  /// Caller-supplied button content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppPressable(
      enabled: onPressed != null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          textStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          foregroundColor: colors.primary,
          backgroundColor: colors.surface.withValues(alpha: 0.6),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.28)),
          minimumSize: const Size(0, appButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
        ),
        child: child,
      ),
    );
  }
}
