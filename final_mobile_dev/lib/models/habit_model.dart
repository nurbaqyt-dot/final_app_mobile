import '../core/utils/date_time_helpers.dart';

class HabitModel {
  const HabitModel({
    required this.id,
    required this.title,
    required this.isDone,
    required this.streak,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isDone;
  final int streak;
  final DateTime createdAt;

  factory HabitModel.fromMap(String id, Map<String, dynamic> map) {
    return HabitModel(
      id: id,
      title: map['title'] as String? ?? '',
      isDone: map['isDone'] as bool? ?? false,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTimeHelpers.parseDate(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
      'streak': streak,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  HabitModel copyWith({
    String? id,
    String? title,
    bool? isDone,
    int? streak,
    DateTime? createdAt,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
