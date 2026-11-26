import "package:flutter/material.dart";

/// An automatically sized sticky sliver with an opaque themed surface.
/// Intrinsic height supports translated labels and accessibility text scaling.
class AppPinnedHeader extends StatelessWidget {
  const AppPinnedHeader({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => PinnedHeaderSliver(
    child: ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(padding: padding, child: child),
    ),
  );
}
