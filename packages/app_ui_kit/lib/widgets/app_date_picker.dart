import "package:flutter/material.dart";

/// Native themed calendar with platform accessibility and dismissal behavior.
abstract final class AppDatePicker {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String title,
  }) => showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: title,
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          datePickerTheme: theme.datePickerTheme.copyWith(
            headerHeadlineStyle: theme.textTheme.titleLarge,
          ),
        ),
        child: child!,
      );
    },
  );
}
