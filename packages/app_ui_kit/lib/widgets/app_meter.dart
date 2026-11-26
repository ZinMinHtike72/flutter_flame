import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

const _fillDuration = Duration(milliseconds: 900);
const _markerWidth = 2.0;
const _markerOverhang = 3.0;

/// Rounded progress track whose fill grows in. An optional [marker] draws a
/// thin line across the track, such as the expected pace.
class AppMeter extends StatelessWidget {
  /// Creates the meter; [value] and [marker] run from 0 to 1.
  const AppMeter({
    required this.value,
    super.key,
    this.height = 8,
    this.color,
    this.marker,
  });

  /// Filled fraction.
  final double value;

  /// Track thickness.
  final double height;

  /// Fill colour; defaults to the theme primary.
  final Color? color;

  /// Marker position, or null for none.
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = color ?? Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(height);
    final track = ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: colors.track,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0, 1)),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : _fillDuration,
            curve: Curves.easeOutCubic,
            builder: (context, factor, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor,
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, borderRadius: radius),
              ),
            ),
          ),
        ),
      ),
    );
    final markerAt = marker;
    if (markerAt == null) {
      return track;
    }
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: height + _markerOverhang * 2,
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, top: _markerOverhang, child: track),
            Positioned(
              top: 0,
              bottom: 0,
              width: _markerWidth,
              left: (markerAt.clamp(0, 1) * constraints.maxWidth).clamp(
                0,
                constraints.maxWidth - _markerWidth,
              ),
              child: ColoredBox(color: colors.textStrong),
            ),
          ],
        ),
      ),
    );
  }
}
