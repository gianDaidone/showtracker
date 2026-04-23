import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Indice dell'ultimo tab sezione visitato (0-3); serve per non
  // "deselezionare" il tab mentre si è nella schermata di ricerca (branch 4).
  int _lastSectionIndex = 0;

  static const _tabs = [
    (icon: Icons.tv, label: 'Serie'),
    (icon: Icons.movie, label: 'Film'),
    (icon: Icons.videogame_asset, label: 'Giochi'),
    if (kDebugMode) (icon: Icons.bug_report, label: 'Debug'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final isSearch = currentIndex == 3;
    // Il branch Debug è il 5° (indice 4); il tab nel nav bar è il 4° (indice 3).
    final isDebug = kDebugMode && currentIndex == 4;

    if (!isSearch && !isDebug) {
      _lastSectionIndex = currentIndex;
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: isSearch
            ? _lastSectionIndex
            : isDebug
                ? 3
                : currentIndex,
        onTap: (i) {
          // Il tab Debug (indice 3 nel nav bar) mappa al branch 4 nel router.
          final branchIndex = (kDebugMode && i == 3) ? 4 : i;
          widget.navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == currentIndex,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
