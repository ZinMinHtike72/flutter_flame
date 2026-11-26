import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

/// A localized destination for the app navigation shell.
final class AppNavigationItem {
  const AppNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Native accessible navigation with a rounded animated selection indicator.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.enabled = true,
  });
  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.onSurface.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.04),
            blurRadius: AppSpacing.lg,
            offset: const Offset(0, -AppSpacing.xs),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        selectedIndex: selectedIndex,
        animationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 400),
        indicatorColor: colors.primary.withValues(alpha: 0.12),
        onDestinationSelected: enabled ? onSelected : null,
        destinations: [
          for (final item in items)
            NavigationDestination(
              enabled: enabled,
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon, color: colors.primary),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
