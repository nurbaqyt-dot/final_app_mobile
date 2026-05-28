import '../core/utils/date_time_helpers.dart';
import '../core/utils/planner_helpers.dart';

class DayPlanModel {
  const DayPlanModel({required this.date, required this.blocks});

  final DateTime date;
  final List<Map<String, dynamic>> blocks;

  double get productivityPercent {
    if (blocks.isEmpty) {
      return 0;
    }
    final productive = blocks
        .where(
          (block) =>
              PlannerHelpers.normalizePlanCategory(
                block['category'] as String? ?? '',
              ) ==
              'study',
        )
        .fold<int>(
          0,
          (sum, block) =>
              sum + PlannerHelpers.blockDurationMinutes(date, block),
        );
    final awake = blocks
        .where(
          (block) =>
              PlannerHelpers.normalizePlanCategory(
                block['category'] as String? ?? '',
              ) !=
              'sleep',
        )
        .fold<int>(
          0,
          (sum, block) =>
              sum + PlannerHelpers.blockDurationMinutes(date, block),
        );
    if (awake == 0) {
      return 0;
    }
    return productive / awake;
  }

  factory DayPlanModel.fromMap(Map<String, dynamic> map) {
    final date = DateTimeHelpers.dateOnly(
      DateTimeHelpers.parseDate(map['date']),
    );
    final rawBlocks = map['blocks'] as List<dynamic>? ?? <dynamic>[];
    return DayPlanModel(
      date: date,
      blocks: rawBlocks
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (block) => PlannerHelpers.sanitizePlanBlock(
              date,
              Map<String, dynamic>.from(block),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'blocks': blocks
          .map((block) => PlannerHelpers.sanitizePlanBlock(date, block))
          .toList(),
    };
  }

  DayPlanModel copyWith({DateTime? date, List<Map<String, dynamic>>? blocks}) {
    return DayPlanModel(date: date ?? this.date, blocks: blocks ?? this.blocks);
  }

  List<Map<String, dynamic>> get sortedBlocks {
    return PlannerHelpers.sortPlanBlocks(blocks, date);
  }
}
