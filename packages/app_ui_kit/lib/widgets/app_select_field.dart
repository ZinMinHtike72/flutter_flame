import "dart:async";

import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:app_ui_kit/widgets/app_select_option.dart";
import "package:app_ui_kit/widgets/app_select_sheet.dart";
import "package:flutter/material.dart";

const _radius = 14.0;
const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 12);
const _minFieldHeight = 48.0;

/// Bordered field showing the chosen option; tapping opens a sheet of
/// [options] titled [sheetTitle].
class AppSelectField extends StatelessWidget {
  /// Creates the field.
  const AppSelectField({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.sheetTitle,
    required this.closeLabel,
    super.key,
    this.sheetSubtitle,
    this.selectionHint,
    this.sheetIcon = AppIcons.list,
    this.layout = AppSelectLayout.list,
  }) : assert(options.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < options.length);

  /// Option labels.
  final List<AppSelectOption> options;

  /// Chosen option.
  final int selectedIndex;

  /// Called with the picked option.
  final ValueChanged<int> onSelected;

  /// Sheet heading.
  final String sheetTitle;

  /// Close button text for the sheet.
  final String closeLabel;

  /// Context for the available choices.
  final String? sheetSubtitle;

  /// Localized explanation of the one-tap selection behavior.
  final String? selectionHint;

  /// Contextual header glyph.
  final IconData sheetIcon;

  /// Rows for descriptive choices; a grid for months.
  final AppSelectLayout layout;

  Future<void> _open(BuildContext context) async {
    final picked = await showAppSelectSheet(
      context: context,
      options: options,
      selectedIndex: selectedIndex,
      title: sheetTitle,
      subtitle: sheetSubtitle,
      hint: selectionHint,
      icon: sheetIcon,
      layout: layout,
      closeLabel: closeLabel,
    );
    if (picked != null && context.mounted) {
      onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: sheetTitle,
      value: options[selectedIndex].label,
      excludeSemantics: true,
      onTap: () => unawaited(_open(context)),
      child: AppPressable(
        child: Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
            side: BorderSide(color: colors.line),
          ),
          child: InkWell(
            onTap: () => unawaited(_open(context)),
            borderRadius: BorderRadius.circular(_radius),
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minFieldHeight),
              child: Padding(
                padding: _padding,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Align(
                          key: ValueKey(selectedIndex),
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            options[selectedIndex].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      AppIcons.expandMore,
                      size: AppSpacing.md + 2,
                      color: colors.textMuted,
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
