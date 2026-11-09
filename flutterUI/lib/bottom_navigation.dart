import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget destination(int index, IconData icon, String label) {
      final selected = selectedIndex == index;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: TextButton(
            onPressed: () => onDestinationSelected(index),
            style: TextButton.styleFrom(
              foregroundColor: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      );
    }

    return BottomAppBar(
      color: colorScheme.surfaceContainer,
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        children: [
          destination(0, Icons.home, 'ホーム'),
          destination(1, Icons.search, '検索'),
          const SizedBox(width: 60),
          destination(2, Icons.person, 'プロフィール'),
          destination(3, Icons.settings, '設定'),
        ],
      ),
    );
  }
}
