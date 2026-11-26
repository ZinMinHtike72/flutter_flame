import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";

/// A compact, counted status selector that scrolls when labels need more room.
class AppStatusFilterBar extends StatelessWidget {
  const AppStatusFilterBar({
    required this.labels,
    required this.counts,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(labels.length == 3),
       assert(counts.length == 3),
       assert(selectedIndex >= 0 && selectedIndex < 3);
  final List<String> labels;
  final List<String> counts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final widths = [
              for (final index in [0, 1, 2])
                _textWidth(context, "${labels[index]} ${counts[index]}") +
                    AppSpacing.xl +
                    AppSpacing.md,
            ];
            final scroll =
                widths.reduce((a, b) => a + b) > constraints.maxWidth;
            final children = [
              for (final index in [0, 1, 2])
                _StatusOption(
                  label: labels[index],
                  count: counts[index],
                  selected: selectedIndex == index,
                  tone: index == 1
                      ? context.appColors.statusPending
                      : index == 2
                      ? context.appColors.statusCompleted
                      : colors.primary,
                  duration: duration,
                  onTap: () => onSelected(index),
                ),
            ];
            if (scroll) {
              return SingleChildScrollView(
                key: ValueKey(selectedIndex),
                reverse: selectedIndex == 2,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final index in [0, 1, 2])
                      SizedBox(width: widths[index], child: children[index]),
                  ],
                ),
              );
            }
            return Row(
              children: [for (final child in children) Expanded(child: child)],
            );
          },
        ),
      ),
    );
  }

  double _textWidth(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.tone,
    required this.duration,
    required this.onTap,
  });
  final String label;
  final String count;
  final bool selected;
  final Color tone;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      onTap: onTap,
      selected: selected,
      label: "$label, $count",
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? colors.surface
              : colors.surface.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: selected
                ? tone.withValues(alpha: 0.3)
                : colors.surface.withValues(alpha: 0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    blurRadius: AppSpacing.sm,
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? tone.withValues(alpha: 0.13)
                            : colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs / 2,
                        ),
                        child: Text(
                          count,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
