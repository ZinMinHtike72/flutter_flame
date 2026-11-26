import "package:flutter/material.dart";

/// Accessible icon action using the application's theme.
class AppIconButton extends StatelessWidget {
  /// Creates an action; null callback disables it.
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.color,
  });

  /// Action glyph.
  final IconData icon;

  /// Callback, or null to disable the action.
  final VoidCallback? onPressed;

  /// Caller-localized tooltip and semantic description.
  final String? tooltip;

  /// Optional foreground override.
  final Color? color;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    color: color,
    icon: Icon(icon),
  );
}
