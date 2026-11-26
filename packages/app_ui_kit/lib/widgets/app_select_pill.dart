import "dart:async";

import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:app_ui_kit/widgets/app_select_option.dart";
import "package:app_ui_kit/widgets/app_select_sheet.dart";
import "package:flutter/material.dart";

const _horizontal = 10.0;
const _vertical = 3.0;
const _radius = 999.0;
const _iconSize = 16.0;
const _minTarget = 44.0;

/// Compact pill showing [label] with a chevron; tapping opens the same sheet
/// of [options] as an `AppSelectField`. Fits an app bar action, such as a
/// month switch.
class AppSelectPill extends StatelessWidget {
  /// Creates the pill.
  const AppSelectPill({
    required this.label,
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

  /// Text on the pill, such as "Nov · to date".
  final String label;

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
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: sheetTitle,
      value: label,
      excludeSemantics: true,
      onTap: () => unawaited(_open(context)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_open(context)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _minTarget,
            minWidth: _minTarget,
          ),
          child: Center(
            child: AppPressable(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(_radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _horizontal,
                    _vertical,
                    _horizontal - 4,
                    _vertical,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                        ),
                      ),
                      Icon(
                        AppIcons.expandMore,
                        size: _iconSize,
                        color: primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
