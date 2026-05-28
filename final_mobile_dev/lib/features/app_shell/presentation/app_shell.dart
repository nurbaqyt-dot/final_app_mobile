import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  static const double _navBarBottomGap = 16;
  static const double _navBarOuterHorizontalPadding = 18;
  static const double _navItemHeight = 68;

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    const items = <({IconData icon, String label})>[
      (icon: Icons.today_outlined, label: 'Сегодня'),
      (icon: Icons.event_note_outlined, label: 'События'),
      (icon: Icons.task_alt_outlined, label: 'Задачи'),
      (icon: Icons.person_outline_rounded, label: 'Профиль'),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: _BottomNavBar(
        items: items,
        navigationShell: navigationShell,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.items, required this.navigationShell});

  final List<({IconData icon, String label})> items;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppShell._navBarOuterHorizontalPadding,
          0,
          AppShell._navBarOuterHorizontalPadding,
          AppShell._navBarBottomGap,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: List<Widget>.generate(items.length, (index) {
                  final item = items[index];
                  final active = navigationShell.currentIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => navigationShell.goBranch(
                          index,
                          initialLocation:
                              index == navigationShell.currentIndex,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          height: AppShell._navItemHeight,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                color: active
                                    ? AppColors.tertiary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
