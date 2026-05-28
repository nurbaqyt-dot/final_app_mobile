import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_logo.dart';
import '../../../../widgets/flow_scaffold.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final page = AppConstants.onboardingPages[pageIndex];
    final isLast = pageIndex == AppConstants.onboardingPages.length - 1;

    return FlowScaffold(
      showAppBar: false,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FlowLogo(size: 60, showText: false),
              const Spacer(),
              TextButton(
                onPressed: () => _finish(context),
                child: const Text('Пропустить'),
              ),
            ],
          ),
          const Spacer(),
          FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    switch (pageIndex) {
                      0 => Icons.auto_awesome_rounded,
                      1 => Icons.psychology_alt_outlined,
                      _ => Icons.calendar_view_day_rounded,
                    },
                    color: AppColors.tertiary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  page['title'] ?? '',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  page['subtitle'] ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.16),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(
              AppConstants.onboardingPages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: index == pageIndex ? 28 : 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == pageIndex
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FlowButton(
            label: isLast ? 'Начать' : 'Далее',
            onPressed: () {
              if (isLast) {
                _finish(context);
                return;
              }
              context.go(switch (pageIndex) {
                0 => AppRoutes.onboarding2,
                1 => AppRoutes.onboarding3,
                _ => AppRoutes.onboarding3,
              });
            },
          ),
          const SizedBox(height: 12),
          const Center(child: FlowLogo(size: 54, showText: false)),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    await context.read<AuthProvider>().markOnboardingSeen();
    if (!context.mounted) {
      return;
    }
    context.go(AppRoutes.login);
  }
}

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen(pageIndex: 0);
  }
}

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen(pageIndex: 1);
  }
}

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen(pageIndex: 2);
  }
}
