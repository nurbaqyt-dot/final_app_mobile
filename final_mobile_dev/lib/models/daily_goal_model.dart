import '../core/utils/date_time_helpers.dart';

class DailyGoalModel {
  const DailyGoalModel({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  factory DailyGoalModel.fromMap(String id, Map<String, dynamic> map) {
    return DailyGoalModel(
      id: id,
      title: map['title'] as String? ?? '',
      isDone: map['isDone'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTimeHelpers.parseDate(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DailyGoalModel copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return DailyGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
