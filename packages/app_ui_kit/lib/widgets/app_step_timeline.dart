import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _dot = 10.0;
const _rail = 2.0;
const _railGap = 4.0;
const _indent = 22.0;
const _stepGap = 14.0;

/// One step of an [AppStepTimeline].
final class AppTimelineStep {
  /// Creates a step.
  const AppTimelineStep({
    required this.title,
    required this.detail,
    required this.done,
  });

  /// Step name.
  final String title;

  /// Date or state under the name.
  final String detail;

  /// Filled dot when done, hollow when still to come.
  final bool done;
}

/// Vertical progress steps joined by a thin rail.
class AppStepTimeline extends StatelessWidget {
  /// Creates the timeline.
  const AppStepTimeline({required this.steps, super.key});

  /// Steps, first to last.
  final List<AppTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _indent,
                  child: Column(
                    children: [
                      const SizedBox(height: _railGap),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: steps[i].done ? primary : colors.track,
                          border: steps[i].done
                              ? null
                              : Border.all(color: colors.textFaint, width: 2),
                        ),
                        child: const SizedBox.square(dimension: _dot),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: _railGap),
                            child: SizedBox(
                              width: _rail,
                              child: ColoredBox(color: colors.line),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < steps.length - 1 ? _stepGap : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textStrong,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          steps[i].detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
