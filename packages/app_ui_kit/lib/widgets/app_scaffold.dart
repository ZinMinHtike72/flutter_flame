import "package:flutter/material.dart";

/// Theme-driven page shell for application feature content.
class AppScaffold extends StatelessWidget {
  /// Creates a keyboard-resizing shell; null color uses the theme.
  const AppScaffold({
    required this.body,
    super.key,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
  });

  /// Page content.
  final Widget body;

  /// Optional application navigation surface.
  final Widget? bottomNavigationBar;

  /// Optional background override.
  final Color? backgroundColor;

  /// Whether the body avoids the software keyboard.
  final bool resizeToAvoidBottomInset;

  /// Whether the body extends behind [bottomNavigationBar], for floating bars.
  final bool extendBody;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    extendBody: extendBody,
    body: body,
    bottomNavigationBar: bottomNavigationBar,
  );
}
