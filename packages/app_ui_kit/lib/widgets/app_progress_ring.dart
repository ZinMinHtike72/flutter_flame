import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

const _sweepDuration = Duration(milliseconds: 1300);

/// Circular progress that sweeps from empty to [value] with a round cap and
/// a soft track, with [child] in the middle. Built on Flutter's
/// CircularProgressIndicator. Reduced motion draws the final arc at once.
class AppProgressRing extends StatelessWidget {
  /// Creates the ring.
  const AppProgressRing({
    required this.value,
    super.key,
    this.size = 96,
    this.strokeWidth = 10,
    this.color,
    this.trackColor,
    this.child,
  });

  /// Progress from 0 to 1; values outside are clamped.
  final double value;

  /// Outer diameter.
  final double size;

  /// Ring thickness.
  final double strokeWidth;

  /// Arc color; defaults to the theme primary.
  final Color? color;

  /// Track color; defaults to a faint primary.
  final Color? trackColor;

  /// Content in the middle, such as the value as text.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final arc = color ?? colors.primary;
    final track = trackColor ?? context.appColors.track;
    final inset = strokeWidth / 2;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(inset),
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: strokeWidth,
                color: track,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(inset),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0, 1)),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : _sweepDuration,
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => CircularProgressIndicator(
                  value: progress,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: arc,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}
