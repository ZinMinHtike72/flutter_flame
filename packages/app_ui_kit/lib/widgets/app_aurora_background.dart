import "dart:math" as math;

import "package:flutter/material.dart";

const _cycle = Duration(seconds: 18);

/// Softly drifting brand-tinted light behind [child]. Reduced motion keeps
/// the glow still.
class AppAuroraBackground extends StatefulWidget {
  /// Creates a background derived from the theme's primary color.
  const AppAuroraBackground({required this.child, super.key});

  /// Content painted above the glow.
  final Widget child;

  @override
  State<AppAuroraBackground> createState() => _AppAuroraBackgroundState();
}

class _AppAuroraBackgroundState extends State<AppAuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
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
    final theme = Theme.of(context);
    final primary = HSLColor.fromColor(theme.colorScheme.primary);
    final isDark = theme.brightness == Brightness.dark;
    return CustomPaint(
      painter: _AuroraPainter(
        animation: _controller,
        base: theme.colorScheme.surface,
        tints: [
          primary.toColor(),
          primary.withHue((primary.hue + 38) % 360).toColor(),
          primary.withHue((primary.hue + 322) % 360).toColor(),
        ],
        strength: isDark ? 0.2 : 0.22,
      ),
      child: widget.child,
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.animation,
    required this.base,
    required this.tints,
    required this.strength,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color base;
  final List<Color> tints;
  final double strength;

  static const _anchors = [
    Offset(0.1, 0.05),
    Offset(0.95, 0.3),
    Offset(0.3, 0.9),
  ];
  static const _radii = [0.75, 0.6, 0.7];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final turn = animation.value * 2 * math.pi;
    final extent = size.longestSide;
    for (final index in List.generate(tints.length, (index) => index)) {
      final phase = turn + index * 2.1;
      final drift = Offset(math.cos(phase), math.sin(phase * 1.3)) * 0.08;
      final anchor = _anchors[index] + drift;
      final center = Offset(anchor.dx * size.width, anchor.dy * size.height);
      final radius = extent * _radii[index];
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              tints[index].withValues(alpha: strength),
              tints[index].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.strength != strength ||
      oldDelegate.tints != tints;
}
