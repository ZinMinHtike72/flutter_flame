import "package:flutter/widgets.dart";

const _pressedScale = 0.96;
const _pressDuration = Duration(milliseconds: 110);
const _releaseDuration = Duration(milliseconds: 420);

/// Shared touch feedback: [child] dips while a finger is down and springs
/// back on release. It only listens to pointers, so [child] keeps handling
/// its own taps. Reduced motion or [enabled] false leaves it still.
class AppPressable extends StatefulWidget {
  /// Creates the wrapper.
  const AppPressable({required this.child, super.key, this.enabled = true});

  /// Content to animate.
  final Widget child;

  /// Whether presses animate.
  final bool enabled;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pressDuration,
    reverseDuration: _releaseDuration,
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: _pressedScale)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
          reverseCurve: Curves.elasticOut,
        ),
      );

  bool get _animates =>
      widget.enabled && !MediaQuery.disableAnimationsOf(context);

  void _press(PointerDownEvent _) {
    if (_animates) {
      _controller.forward();
    }
  }

  void _release(PointerEvent _) {
    if (_controller.value > 0) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _press,
    onPointerUp: _release,
    onPointerCancel: _release,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
