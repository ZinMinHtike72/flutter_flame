import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/widgets.dart";

/// One-shot staggered entrance, respecting the device's reduced-motion setting.
class AppEntrance extends StatelessWidget {
  const AppEntrance({required this.child, super.key, this.delay = 0});
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      child: child,
      builder: (context, value, child) {
        final progress = Interval(
          delay,
          1,
          curve: Curves.easeOutCubic,
        ).transform(value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, AppSpacing.lg * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}
