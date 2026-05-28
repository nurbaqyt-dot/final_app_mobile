import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';

class FlowLogo extends StatelessWidget {
  const FlowLogo({
    super.key,
    this.size = 88,
    this.showText = true,
    this.alignment = Alignment.center,
  });

  final double size;
  final bool showText;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              color: AppColors.surface.withValues(alpha: 0.92),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.22),
              child: Image.asset(AppConstants.logoAsset, fit: BoxFit.cover),
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 14),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ИИ-планер для студентов JIHC',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
