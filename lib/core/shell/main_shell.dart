import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants.dart';
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
    (
      branch: 0,
      icon: Icons.tv_outlined,
      activeIcon: Icons.tv_rounded,
      label: 'Serie'
    ),
    (
      branch: 1,
      icon: Icons.movie_outlined,
      activeIcon: Icons.movie,
      label: 'Film'
    ),
    if (kEnableGames)
      (
        branch: 2,
        icon: Icons.videogame_asset_outlined,
        activeIcon: Icons.videogame_asset,
        label: 'Giochi'
      ),
    (
      branch: 3,
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profilo'
    ),
    if (kDebugMode)
      (
        branch: 5,
        icon: Icons.bug_report_outlined,
        activeIcon: Icons.bug_report,
        label: 'Debug'
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final isSearch = currentIndex == 4;
    final isDebug = kDebugMode && currentIndex == 5;

    if (!isSearch && !isDebug) {
      _lastSectionIndex = currentIndex;
    }

    final tabWidth = math.max(
        1.0,
        (MediaQuery.sizeOf(context).width -
                MediaQuery.paddingOf(context).horizontal -
                32) /
            _tabs.length);
    var navigationHeight = 64.0;
    for (final tab in _tabs) {
      final painter = TextPainter(
        text: TextSpan(
            text: tab.label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout(maxWidth: tabWidth);
      navigationHeight = math.max(navigationHeight, 48 + painter.height);
      painter.dispose();
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: navigationHeight,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final activeIndex = isSearch ? _lastSectionIndex : currentIndex;

              return Stack(
                children: [
                  // Icone e testi
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final t = _tabs[index];
                      final isSelected = t.branch == activeIndex;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            widget.navigationShell.goBranch(
                              t.branch,
                              initialLocation: t.branch == currentIndex,
                            );
                          },
                          child: Semantics(
                              button: true,
                              selected: isSelected,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    scale: isSelected ? 1.15 : 1.0,
                                    child: Icon(
                                      isSelected ? t.activeIcon : t.icon,
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    child: Text(t.label),
                                  ),
                                ],
                              )),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
