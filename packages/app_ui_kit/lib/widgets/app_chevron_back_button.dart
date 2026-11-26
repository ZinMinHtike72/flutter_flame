import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";

class AppChevronBackButton extends StatelessWidget {
  const AppChevronBackButton({
    required this.onPressed,
    required this.tooltip,
    super.key,
  });
  final VoidCallback onPressed;
  final String tooltip;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            side: BorderSide(color: colors.onSurface.withValues(alpha: 0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                AppIcons.chevronBack,
                size: 25,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
