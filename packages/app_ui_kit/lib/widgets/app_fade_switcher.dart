import "package:flutter/widgets.dart";

/// Default page cross-fade time.
const appFadeSwitchDuration = Duration(milliseconds: 220);

/// Cross-fades between pages whenever [pageKey] changes: the new page fades
/// in with `easeOutCubic` while the old one fades out with `easeInCubic`.
///
/// The outgoing page ignores pointers while it fades, so a quick second tap
/// can never hit a control that is already leaving. Reduced motion switches
/// instantly.
class AppFadeSwitcher extends StatelessWidget {
  /// Creates the switcher.
  const AppFadeSwitcher({
    required this.pageKey,
    required this.child,
    super.key,
    this.duration = appFadeSwitchDuration,
  });

  /// Identifies the page; a new value starts a cross-fade.
  final Object pageKey;

  /// The current page.
  final Widget child;

  /// Cross-fade time.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey<Object>(pageKey);
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?currentChild]),
      // A new closure each build, so outgoing pages are rebuilt with
      // `ignoring: true` as soon as they stop being current.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: IgnorePointer(ignoring: child.key != current, child: child),
      ),
      child: KeyedSubtree(key: current, child: child),
    );
  }
}
