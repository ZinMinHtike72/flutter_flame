import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";

/// A high-contrast image overlay action with a full-size touch target.
class AppImageCloseButton extends StatelessWidget {
  const AppImageCloseButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });
  final String tooltip;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 2,
      shadowColor: colors.onSurface.withValues(alpha: 0.16),
      shape: CircleBorder(
        side: BorderSide(color: colors.onSurface.withValues(alpha: 0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AppIconButton(
        icon: AppIcons.close,
        tooltip: tooltip,
        onPressed: onPressed,
        color: onPressed == null ? null : colors.onSurface,
      ),
    );
  }
}
