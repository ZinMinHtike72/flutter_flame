import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

/// Native modal route for an acknowledged, non-dismissible operation.
abstract final class AppModal {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    VoidCallback? onBackAttempted,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onBackAttempted?.call();
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: builder(context),
        ),
      ),
    ),
  );
}
