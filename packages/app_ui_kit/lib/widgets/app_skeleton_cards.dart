import "package:app_ui_kit/widgets/app_skeleton.dart";
import "package:flutter/widgets.dart";

const _radius = 20.0;
const _gap = 12.0;

/// Shimmering stack of card placeholders with the given [heights].
class AppSkeletonCards extends StatelessWidget {
  /// Creates the skeleton.
  const AppSkeletonCards({
    required this.heights,
    super.key,
    this.semanticsLabel,
  });

  /// Card heights, top to bottom.
  final List<double> heights;

  /// Screen reader text.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => AppSkeleton(
    semanticsLabel: semanticsLabel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < heights.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          AppSkeletonBox(height: heights[i], radius: _radius),
        ],
      ],
    ),
  );
}
