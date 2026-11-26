import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/widgets.dart";

const _maxContentWidth = 560.0;
const _topGap = 4.0;

/// Page body sliver: page-side padding that centres content up to
/// [maxWidth], room for the floating navigation bar at the bottom, and the
/// given [sliver].
class AppSliverBody extends StatelessWidget {
  /// Creates the body.
  const AppSliverBody({
    required this.sliver,
    super.key,
    this.maxWidth = _maxContentWidth,
  });

  /// Content sliver, such as a [SliverList].
  final Widget sliver;

  /// Widest the content may grow.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final side = width - AppSpacing.md * 2 > maxWidth
        ? (width - maxWidth) / 2
        : AppSpacing.md;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        side,
        _topGap,
        side,
        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      sliver: sliver,
    );
  }
}
