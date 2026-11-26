import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/widgets.dart";

const _fadeDuration = Duration(milliseconds: 320);

/// Fades and lifts [child] in whenever [trigger] changes, such as the tab
/// index of a navigation shell. Keeps [child]'s state; reduced motion skips.
class AppFadeThrough extends StatefulWidget {
  /// Creates the wrapper.
  const AppFadeThrough({required this.trigger, required this.child, super.key});

  /// Any change replays the entrance.
  final Object trigger;

  /// Content to reveal.
  final Widget child;

  @override
  State<AppFadeThrough> createState() => _AppFadeThroughState();
}

class _AppFadeThroughState extends State<AppFadeThrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _fadeDuration,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant AppFadeThrough oldWidget) {
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
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, AppSpacing.md * (1 - _curve.value)),
        child: child,
      ),
    ),
  );
}
