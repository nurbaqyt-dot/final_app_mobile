import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/date_time_helpers.dart';
import '../core/utils/planner_helpers.dart';
import 'flow_card.dart';

class TimelineBlockCard extends StatelessWidget {
  const TimelineBlockCard({
    super.key,
    required this.date,
    required this.block,
    this.onTap,
  });

  final DateTime date;
  final Map<String, dynamic> block;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = PlannerHelpers.hexToColor(
      block['color'] as String? ?? PlannerHelpers.categoryHex('personal'),
    );
    final start = PlannerHelpers.blockStart(date, block);
    final end = PlannerHelpers.blockEnd(date, block);
    final duration = PlannerHelpers.blockDurationMinutes(date, block);
    return FlowCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 72,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block['title'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${DateTimeHelpers.formatTime(start)} - ${DateTimeHelpers.formatTime(end)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$duration мин',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              PlannerHelpers.categoryLabel(
                block['category'] as String? ?? 'personal',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
