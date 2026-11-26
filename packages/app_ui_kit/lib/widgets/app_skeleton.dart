import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _sweepPeriod = Duration(milliseconds: 1400);

/// How far the moving band leans from the track colour toward the text colour.
const _shineStrength = 0.08;

/// Loading placeholder: a light band sweeps across every [AppSkeletonBox]
/// inside [child], so a whole layout shimmers in step. The boxes use the
/// theme's track colour and the band is a touch darker in light mode and
/// lighter in dark mode. Reduced motion keeps the boxes still.
class AppSkeleton extends StatefulWidget {
  /// Creates the shimmer around a layout of skeleton boxes.
  const AppSkeleton({required this.child, super.key, this.semanticsLabel});

  /// Layout of [AppSkeletonBox] placeholders.
  final Widget child;

  /// Screen reader text, such as "Loading".
  final String? semanticsLabel;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _sweepPeriod,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.appColors.track;
    final shine = Color.lerp(
      base,
      Theme.of(context).colorScheme.onSurface,
      _shineStrength,
    )!;
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final shift = _controller.value * 3 - 1.5;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(shift - 1, -0.3),
              end: Alignment(shift + 1, 0.3),
              colors: [base, shine, base],
              stops: const [0.3, 0.5, 0.7],
            ).createShader(bounds),
            child: child,
          );
        },
      ),
    );
  }
}

/// One rounded placeholder block for [AppSkeleton].
class AppSkeletonBox extends StatelessWidget {
  /// Creates a block; a null [width] fills the available width.
  const AppSkeletonBox({
    required this.height,
    super.key,
    this.width,
    this.radius = AppSpacing.sm,
  });

  /// Block height.
  final double height;

  /// Block width, or null to fill.
  final double? width;

  /// Corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}
