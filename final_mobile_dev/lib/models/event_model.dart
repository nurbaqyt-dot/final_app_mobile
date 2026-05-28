import '../core/utils/date_time_helpers.dart';
import '../core/utils/planner_helpers.dart';

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.color,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String color;

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      startTime: DateTimeHelpers.parseDate(map['startTime']),
      endTime: DateTimeHelpers.parseDate(map['endTime']),
      category: PlannerHelpers.normalizeEventCategory(
        map['category'] as String? ?? '',
      ),
      color: PlannerHelpers.normalizeHexColor(
        map['color'],
        fallback: PlannerHelpers.categoryHex(
          PlannerHelpers.normalizeEventCategory(
            map['category'] as String? ?? '',
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'category': category,
      'color': color,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? color,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      color: color ?? this.color,
    );
  }
}
