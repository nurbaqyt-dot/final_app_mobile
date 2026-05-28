import '../core/utils/date_time_helpers.dart';

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.photoUrl,
    required this.createdAt,
    required this.totalFocusMinutes,
    required this.currentStreak,
  });

  final String id;
  final String name;
  final String studentId;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final int totalFocusMinutes;
  final int currentStreak;

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      name: map['name'] as String? ?? 'JIHC Student',
      studentId: map['studentId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      createdAt: DateTimeHelpers.parseDate(map['createdAt']),
      totalFocusMinutes: (map['totalFocusMinutes'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'studentId': studentId,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'totalFocusMinutes': totalFocusMinutes,
      'currentStreak': currentStreak,
    };
  }

  AppUserModel copyWith({
    String? id,
    String? name,
    String? studentId,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    int? totalFocusMinutes,
    int? currentStreak,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}
