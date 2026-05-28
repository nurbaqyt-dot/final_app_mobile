import '../core/utils/date_time_helpers.dart';
import '../core/utils/planner_helpers.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.isDone,
    required this.difficultyLevel,
  });

  final String id;
  final String title;
  final DateTime deadline;
  final String priority;
  final bool isDone;
  final int difficultyLevel;

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      title: map['title'] as String? ?? '',
      deadline: DateTimeHelpers.parseDate(map['deadline']),
      priority: PlannerHelpers.normalizePriority(
        map['priority'] as String? ?? '',
      ),
      isDone: map['isDone'] as bool? ?? map['isCompleted'] as bool? ?? false,
      difficultyLevel:
          ((map['difficultyLevel'] as num?)?.toInt() ??
                  (map['difficulty'] as num?)?.toInt() ??
                  3)
              .clamp(1, 5),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'deadline': deadline.toIso8601String(),
      'priority': priority,
      'isDone': isDone,
      'isCompleted': isDone,
      'difficultyLevel': difficultyLevel,
      'difficulty': difficultyLevel,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    String? priority,
    bool? isDone,
    int? difficultyLevel,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }
}
