import "dart:ui";

import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_bottom_navigation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _barHeight = 64.0;
const _barMaxWidth = 480.0;
const _barRadius = 26.0;
const _sideInset = 12.0;
const _bottomInset = 14.0;
const _blurSigma = 16.0;
const _surfaceAlpha = 0.82;
const _iconSize = 22.0;
const _itemWidth = 60.0;
const _shadowBlur = 24.0;
const _shadowOffset = 8.0;
const _morphDuration = Duration(milliseconds: 260);

/// Floating frosted navigation bar: a card-coloured, blurred capsule with a
/// hairline border. Each destination is an icon over a short label, faint
/// when idle and primary + semibold when selected; the selected icon hops
/// and every change gives a light haptic tick. Reduced motion skips motion.
class AppGlassNavigationBar extends StatelessWidget {
  /// Creates the bar.
  const AppGlassNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Destinations, left to right.
  final List<AppNavigationItem> items;

  /// Index of the current destination.
  final int selectedIndex;

  /// Called with the tapped index, including the current one.
  final ValueChanged<int> onSelected;

  /// Height the bar occupies above the bottom safe area, for content padding.
  static const double occupiedHeight = _barHeight + _bottomInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final light = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(_barRadius);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        _sideInset,
        0,
        _sideInset,
        _bottomInset,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _barMaxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: light
                  ? [
                      BoxShadow(
                        color: colors.textStrong.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                      BoxShadow(
                        color: colors.cardShadow,
                        blurRadius: _shadowBlur,
                        offset: const Offset(0, _shadowOffset),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurSigma,
                  sigmaY: _blurSigma,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: colors.card.withValues(alpha: _surfaceAlpha),
                    border: Border.all(color: colors.line),
                  ),
                  child: SizedBox(
                    height: _barHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (var index = 0; index < items.length; index++)
                          _Destination(
                            item: items[index],
                            selected: index == selectedIndex,
                            onTap: () {
                              if (index != selectedIndex) {
                                HapticFeedback.selectionClick();
                              }
                              onSelected(index);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _morphDuration;
    final color = selected ? theme.colorScheme.primary : colors.textFaint;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: _itemWidth,
          height: _barHeight,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: duration,
            builder: (context, animatedColor, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  offset: selected ? const Offset(0, -0.08) : Offset.zero,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: duration,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: Tween(begin: 0.7, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      key: ValueKey(selected),
                      color: animatedColor,
                      size: _iconSize,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: animatedColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
