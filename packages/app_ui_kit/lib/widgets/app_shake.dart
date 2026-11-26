import "dart:math" as math;

import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/widgets.dart";

const _shakeDuration = Duration(milliseconds: 480);
const _oscillations = 4;

/// Shakes [child] horizontally each time [trigger] changes, for example on
/// rejected input. Reduced motion skips the shake.
class AppShake extends StatefulWidget {
  /// Creates a shake wrapper.
  const AppShake({required this.trigger, required this.child, super.key});

  /// Any change to this value starts one shake.
  final int trigger;

  /// Content to shake.
  final Widget child;

  @override
  State<AppShake> createState() => _AppShakeState();
}

class _AppShakeState extends State<AppShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _shakeDuration,
  );

  @override
  void didUpdateWidget(covariant AppShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
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
    builder: (context, child) {
      final progress = _controller.value;
      final dx =
          math.sin(progress * _oscillations * 2 * math.pi) *
          AppSpacing.md *
          (1 - progress);
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
  );
}
