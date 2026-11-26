import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";

const _size = 40.0;
const _iconSize = 20.0;

/// 40 round card-coloured button with a hairline border, such as back,
/// share or notifications in a page header.
class AppRoundIconButton extends StatelessWidget {
  /// Creates the button.
  const AppRoundIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Glyph.
  final IconData icon;

  /// Tooltip and screen reader text.
  final String label;

  /// Action.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: AppPressable(
          child: GestureDetector(
            onTap: onPressed,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
                border: Border.all(color: colors.line),
              ),
              child: SizedBox.square(
                dimension: _size,
                child: Icon(icon, size: _iconSize, color: colors.textStrong),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
