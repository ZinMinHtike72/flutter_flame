import "dart:async";

import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_bottom_sheet.dart";
import "package:app_ui_kit/widgets/app_entrance.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:app_ui_kit/widgets/app_select_option.dart";
import "package:app_ui_kit/widgets/app_select_option_tile.dart";
import "package:app_ui_kit/widgets/app_sheet_header.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _gridMinWidth = 96.0;
const _gridHeight = 120.0;
const _maxGridColumns = 3;
const _maxStaggerIndex = 5;
const _staggerStep = 0.045;

/// Opens an [AppSelectSheet] of [options] and returns the picked index,
/// or null when it is closed. Shared by [AppSelectSheet]'s triggers, such as
/// a select field or a select pill.
Future<int?> showAppSelectSheet({
  required BuildContext context,
  required List<AppSelectOption> options,
  required int selectedIndex,
  required String title,
  required String closeLabel,
  String? subtitle,
  String? hint,
  IconData icon = AppIcons.list,
  AppSelectLayout layout = AppSelectLayout.list,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return AppBottomSheet.show<int>(
    context: context,
    scrollable: false,
    surfaceColor: context.appColors.card,
    animationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 380),
      reverseDuration: Duration(milliseconds: 260),
    ),
    builder: (sheetContext) => AppSelectSheet(
      options: options,
      selectedIndex: selectedIndex,
      title: title,
      subtitle: subtitle,
      hint: hint,
      icon: icon,
      layout: layout,
      closeLabel: closeLabel,
      onClose: () => Navigator.of(sheetContext).pop(),
      onSelected: (index) {
        unawaited(HapticFeedback.selectionClick());
        Navigator.of(sheetContext).pop(index);
      },
    ),
  );
}

/// Compact heading and independently scrolling choices for [AppSelectLayout].
class AppSelectSheet extends StatelessWidget {
  const AppSelectSheet({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    super.key,
    this.subtitle,
    this.hint,
    this.icon = AppIcons.list,
    this.layout = AppSelectLayout.list,
  });

  final List<AppSelectOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String title;
  final String closeLabel;
  final VoidCallback onClose;
  final String? subtitle;
  final String? hint;
  final IconData icon;
  final AppSelectLayout layout;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSheetHeader(
        compact: true,
        icon: icon,
        title: title,
        subtitle: subtitle,
        closeLabel: closeLabel,
        onClose: onClose,
      ),
      const SizedBox(height: AppSpacing.lg),
      Flexible(
        child: Scrollbar(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final columns = (constraints.maxWidth / (_gridMinWidth * scale))
                  .floor()
                  .clamp(1, _maxGridColumns);
              // At large text sizes, flowing rows avoid clipping descriptions.
              if (layout == AppSelectLayout.list || columns == 1) {
                return ListView.separated(
                  shrinkWrap: true,
                  primary: true,
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  itemCount: options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _choice(index),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                primary: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                itemCount: options.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: _gridHeight * scale,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                itemBuilder: (context, index) => _choice(index, grid: true),
              );
            },
          ),
        ),
      ),
      if (hint != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          hint!,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.appColors.textMuted),
        ),
      ],
    ],
  );

  Widget _choice(int index, {bool grid = false}) => AppEntrance(
    delay: index.clamp(0, _maxStaggerIndex) * _staggerStep,
    child: AppSelectOptionTile(
      option: options[index],
      selected: selectedIndex == index,
      grid: grid,
      onPressed: () => onSelected(index),
    ),
  );
}
