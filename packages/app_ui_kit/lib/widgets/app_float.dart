import "dart:math" as math;

import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/widgets.dart";

/// Gently bobs [child] up and down. Reduced motion keeps it still.
class AppFloat extends StatefulWidget {
  /// Creates a floating wrapper.
  const AppFloat({
    required this.child,
    super.key,
    this.amplitude = AppSpacing.sm,
    this.period = const Duration(seconds: 4),
  });

  /// Content to float.
  final Widget child;

  /// Maximum vertical travel in logical pixels.
  final double amplitude;

  /// Duration of one full up-and-down cycle.
  final Duration period;

  @override
  State<AppFloat> createState() => _AppFloatState();
}

class _AppFloatState extends State<AppFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        math.sin(_controller.value * 2 * math.pi) * widget.amplitude / 2,
      ),
      child: child,
    ),
  );
}
