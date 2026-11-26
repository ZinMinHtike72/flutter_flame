import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:app_ui_kit/widgets/app_select_option.dart";
import "package:flutter/material.dart";

const _tileRadius = 20.0;
const _iconExtent = 44.0;
const _checkExtent = 24.0;
const _rowMinHeight = 76.0;
const _selectionDuration = Duration(milliseconds: 220);

/// A keyboard-accessible choice with an explicit selected checkmark.
class AppSelectOptionTile extends StatelessWidget {
  const AppSelectOptionTile({
    required this.option,
    required this.selected,
    required this.onPressed,
    super.key,
    this.grid = false,
  });

  final AppSelectOption option;
  final bool selected;
  final VoidCallback onPressed;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(_tileRadius);
    return Semantics(
      label: option.label,
      value: grid ? null : option.supportingText,
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: AppPressable(
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : _selectionDuration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? colors.heroStart : colors.canvas,
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.heroStart,
                      Color.lerp(colors.heroStart, colors.heroMid, 0.35)!,
                    ],
                  )
                : null,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? colors.heroMid.withValues(alpha: 0.5)
                  : colors.line,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.heroStart.withValues(alpha: 0.18),
                      blurRadius: AppSpacing.md,
                      offset: const Offset(0, AppSpacing.xs),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              splashFactory: NoSplash.splashFactory,
              hoverColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.06),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _rowMinHeight),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: grid
                      ? _GridContent(option: option, selected: selected)
                      : _RowContent(option: option, selected: selected),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({required this.option, required this.selected});

  final AppSelectOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        if (option.icon != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.16)
                  : colors.card,
              borderRadius: BorderRadius.circular(AppSpacing.md - 2),
            ),
            child: SizedBox.square(
              dimension: _iconExtent,
              child: Icon(
                option.icon,
                size: AppSpacing.lg,
                color: selected ? Colors.white : primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md - AppSpacing.xs),
        ],
        Expanded(
          child: _OptionText(option: option, selected: selected),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SelectionCheck(selected: selected),
      ],
    );
  }
}

class _GridContent extends StatelessWidget {
  const _GridContent({required this.option, required this.selected});

  final AppSelectOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _SelectionCheck(selected: selected),
      ),
      const Spacer(),
      _OptionText(option: option, selected: selected, compact: true),
    ],
  );
}

class _OptionText extends StatelessWidget {
  const _OptionText({
    required this.option,
    required this.selected,
    this.compact = false,
  });

  final AppSelectOption option;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          compact ? option.shortLabel ?? option.label : option.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : colors.textStrong,
          ),
        ),
        if (option.supportingText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            option.supportingText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? Colors.white.withValues(alpha: 0.92)
                  : colors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _SelectionCheck extends StatelessWidget {
  const _SelectionCheck({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? Colors.white : Colors.transparent,
      border: selected
          ? null
          : Border.all(color: context.appColors.line, width: 1.5),
    ),
    child: SizedBox.square(
      dimension: _checkExtent,
      child: selected
          ? Icon(AppIcons.check, size: 16, color: context.appColors.heroStart)
          : null,
    ),
  );
}
