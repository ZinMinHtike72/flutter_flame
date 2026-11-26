import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

/// Two equal, accessible tabs with a sliding surface and animated selection.
class AppViewTabs extends StatelessWidget {
  const AppViewTabs({
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(labels.length == 2),
       assert(icons.length == 2),
       assert(selectedIndex >= 0 && selectedIndex < 2);
  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 380);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                alignment: selectedIndex == 0
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.07),
                          blurRadius: AppSpacing.sm,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final index in [0, 1])
                  Expanded(
                    child: _ViewTab(
                      label: labels[index],
                      icon: icons[index],
                      selected: selectedIndex == index,
                      duration: duration,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  const _ViewTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.duration,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: duration,
                    curve: Curves.easeOutBack,
                    child: TweenAnimationBuilder<Color?>(
                      duration: duration,
                      tween: ColorTween(end: foreground),
                      builder: (context, color, child) =>
                          Icon(icon, size: 19, color: color),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
