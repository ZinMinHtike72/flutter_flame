import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_float.dart";
import "package:flutter/material.dart";

const _radius = 24.0;
const _padding = 18.0;
const _bubble = 220.0;
const _bubbleRight = -70.0;
const _bubbleTop = -90.0;
const _bubbleAlpha = 0.12;
const _bubblePeriod = Duration(seconds: 7);
const _chipPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 3);
const _tilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
const _tileRadius = 14.0;

/// Brand gradient card with a softly floating bubble, for headline money.
/// Its content is white in both themes.
class AppHeroCard extends StatelessWidget {
  /// Creates the card.
  const AppHeroCard({required this.child, super.key});

  /// White content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.heroStart, colors.heroMid, colors.heroEnd],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: _bubbleRight,
              top: _bubbleTop,
              child: AppFloat(
                period: _bubblePeriod,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: _bubbleAlpha),
                  ),
                  child: const SizedBox.square(dimension: _bubble),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(_padding), child: child),
          ],
        ),
      ),
    );
  }
}

/// Small rounded label on an [AppHeroCard]; [outlined] for a quieter one.
class AppHeroChip extends StatelessWidget {
  /// Creates the chip.
  const AppHeroChip({required this.label, super.key, this.outlined = false});

  /// Text.
  final String label;

  /// Border only, no fill.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: outlined ? null : white.withValues(alpha: 0.18),
        border: outlined
            ? Border.all(color: white.withValues(alpha: 0.45))
            : null,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: _chipPadding,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: white,
          ),
        ),
      ),
    );
  }
}

/// Translucent label/value tile on an [AppHeroCard].
class AppHeroTile extends StatelessWidget {
  /// Creates the tile.
  const AppHeroTile({required this.label, required this.value, super.key});

  /// Small label.
  final String label;

  /// Value, usually white text or a count-up.
  final Widget value;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(_tileRadius),
      ),
      child: Padding(
        padding: _tilePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            value,
          ],
        ),
      ),
    );
  }
}

/// White text style for values on an [AppHeroCard].
TextStyle? appHeroValueStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .bodyLarge
    ?.copyWith(fontWeight: FontWeight.w600, color: Colors.white);
