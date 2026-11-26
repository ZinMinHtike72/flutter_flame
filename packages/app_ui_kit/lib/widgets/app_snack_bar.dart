import "package:flutter/material.dart";

/// Native, theme-aware feedback for operations.
abstract final class AppSnackBar {
  /// Reports a recoverable failure.
  static void showError(BuildContext context, {required String message}) {
    final colors = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      foreground: colors.onErrorContainer,
      background: colors.errorContainer,
    );
  }

  /// Confirms a completed action, such as copying text.
  static void showSuccess(BuildContext context, {required String message}) {
    final colors = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      foreground: colors.onInverseSurface,
      background: colors.inverseSurface,
    );
  }

  /// Shares a neutral notice, such as an empty inbox.
  static void showInfo(BuildContext context, {required String message}) {
    final colors = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      foreground: colors.onInverseSurface,
      background: colors.inverseSurface,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color foreground,
    required Color background,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }
}
