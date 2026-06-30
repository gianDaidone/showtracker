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
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
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
              final activeIndex =
                  isSearch ? _lastSectionIndex : (isDebug ? 3 : currentIndex);
              final tabWidth = constraints.maxWidth / _tabs.length;

              return Stack(
                children: [
                  // Sfondo animato (il "badge")
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    left: tabWidth * activeIndex,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(35),
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                  // Icone e testi
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final t = _tabs[index];
                      final isSelected = index == activeIndex;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final branchIndex =
                                (kDebugMode && index == 3) ? 4 : index;
                            widget.navigationShell.goBranch(
                              branchIndex,
                              initialLocation: branchIndex == currentIndex,
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                scale: isSelected ? 1.15 : 1.0,
                                child: Icon(
                                  t.icon,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                child: Text(t.label),
                              ),
                            ],
                          ),
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
