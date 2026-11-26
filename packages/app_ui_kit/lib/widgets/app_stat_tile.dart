import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _iconBox = 30.0;
const _iconSize = 17.0;
const _radius = 14.0;
const _padding = EdgeInsets.all(10);

/// Compact tinted tile: an icon badge, a small [label] and a strong
/// [value], such as "Days left · 9". Used in a row of two or three.
class AppStatTile extends StatelessWidget {
  /// Creates the tile.
  const AppStatTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.color,
  });

  /// Badge glyph.
  final IconData icon;

  /// What the value is.
  final String label;

  /// The value as text.
  final String value;

  /// Accent for the badge; defaults to the theme primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final accent = color ?? theme.colorScheme.primary;
    return Semantics(
      container: true,
      label: "$label, $value",
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: colors.line),
          ),
          child: Padding(
            padding: _padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(_iconBox / 3),
                  ),
                  child: SizedBox.square(
                    dimension: _iconBox,
                    child: Icon(icon, size: _iconSize, color: accent),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textStrong,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
