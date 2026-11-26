import "package:flutter/material.dart";

/// Low-emphasis inline action, such as "Resend code".
class AppTextButton extends StatelessWidget {
  /// Creates an action; null [onPressed] disables it.
  const AppTextButton({
    required this.onPressed,
    required this.child,
    super.key,
  });

  /// Action to perform when pressed.
  final VoidCallback? onPressed;

  /// Caller-supplied content.
  final Widget child;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      textStyle: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    child: child,
  );
}
