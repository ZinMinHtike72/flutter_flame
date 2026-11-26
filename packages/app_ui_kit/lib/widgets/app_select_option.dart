import "package:flutter/widgets.dart";

/// Presentation of the choices in a selection sheet.
enum AppSelectLayout { list, grid }

/// Display information for one choice, independent of a feature's data.
@immutable
class AppSelectOption {
  const AppSelectOption({
    required this.label,
    this.shortLabel,
    this.supportingText,
    this.icon,
  });

  /// Full accessible name, also displayed in the closed field.
  final String label;

  /// Optional compact name for a calendar-style grid.
  final String? shortLabel;

  /// Description in a row, or year in a calendar tile.
  final String? supportingText;

  /// Contextual glyph for a row.
  final IconData? icon;
}
