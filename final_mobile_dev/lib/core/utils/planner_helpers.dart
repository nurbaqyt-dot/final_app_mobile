import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'date_time_helpers.dart';

class PlannerHelpers {
  const PlannerHelpers._();

  static const Map<String, String> _planCategoryLabels = {
    'study': 'Учёба',
    'sport': 'Спорт',
    'rest': 'Отдых',
    'sleep': 'Сон',
    'personal': 'Личное',
  };

  static const Map<String, String> _eventCategoryAliases = {
    'study': 'Учёба',
    'учеба': 'Учёба',
    'учёба': 'Учёба',
    'sport': 'Спорт',
    'споpт': 'Спорт',
    'спорт': 'Спорт',
    'work': 'Работа',
    'работа': 'Работа',
    'rest': 'Отдых',
    'отдых': 'Отдых',
    'personal': 'Личное',
    'личное': 'Личное',
    'other': 'Другое',
    'другое': 'Другое',
  };

  static const Map<String, String> _priorityAliases = {
    'high': 'Высокий',
    'высокий': 'Высокий',
    'medium': 'Средний',
    'средний': 'Средний',
    'low': 'Низкий',
    'низкий': 'Низкий',
  };

  static String normalizeEventCategory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Личное';
    }
    return _eventCategoryAliases[trimmed.toLowerCase()] ?? trimmed;
  }

  static String normalizePriority(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Средний';
    }
    return _priorityAliases[trimmed.toLowerCase()] ?? trimmed;
  }

  static String normalizePlanCategory(String value) {
    switch (value.trim().toLowerCase()) {
      case 'study':
      case 'учёба':
      case 'учеба':
        return 'study';
      case 'sport':
      case 'споpт':
      case 'спорт':
        return 'sport';
      case 'rest':
      case 'отдых':
        return 'rest';
      case 'sleep':
      case 'сон':
        return 'sleep';
      default:
        return 'personal';
    }
  }

  static String planCategoryFromEventCategory(String category) {
    switch (normalizeEventCategory(category)) {
      case 'Учёба':
        return 'study';
      case 'Спорт':
        return 'sport';
      case 'Отдых':
        return 'rest';
      default:
        return 'personal';
    }
  }

  static String categoryLabel(String category) {
    final normalizedEvent = normalizeEventCategory(category);
    if (AppConstants.eventCategories.contains(normalizedEvent)) {
      return normalizedEvent;
    }
    return _planCategoryLabels[normalizePlanCategory(category)] ?? 'Другое';
  }

  static String priorityLabel(String priority) {
    return normalizePriority(priority);
  }

  static Color eventCategoryColor(String category) {
    switch (normalizeEventCategory(category)) {
      case 'Учёба':
        return const Color(0xFF7209B7);
      case 'Спорт':
        return const Color(0xFF9D4EDD);
      case 'Работа':
        return const Color(0xFF560BAD);
      case 'Отдых':
        return const Color(0xFFE0AAFF);
      case 'Личное':
        return const Color(0xFFB5179E);
      case 'Другое':
      default:
        return const Color(0xFF7B2CBF);
    }
  }

  static Color planCategoryColor(String category) {
    switch (normalizePlanCategory(category)) {
      case 'study':
        return const Color(0xFF7209B7);
      case 'sport':
        return const Color(0xFF9D4EDD);
      case 'rest':
        return const Color(0xFFE0AAFF);
      case 'sleep':
        return const Color(0xFF560BAD);
      default:
        return const Color(0xFFB5179E);
    }
  }

  static Color categoryColor(String category) {
    if (AppConstants.eventCategories.contains(
      normalizeEventCategory(category),
    )) {
      return eventCategoryColor(category);
    }
    return planCategoryColor(category);
  }

  static String categoryHex(String category) {
    final color = categoryColor(category);
    return colorToHex(color);
  }

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static String normalizeHexColor(
    dynamic raw, {
    String fallback = AppConstants.primaryHex,
  }) {
    if (raw is int) {
      return colorToHex(Color(raw));
    }
    if (raw is String) {
      final normalized = raw.replaceAll('#', '').trim().toUpperCase();
      if (normalized.length == 6 &&
          RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized)) {
        return '#$normalized';
      }
      if (normalized.length == 8 &&
          RegExp(r'^[0-9A-F]{8}$').hasMatch(normalized)) {
        return '#${normalized.substring(2)}';
      }
    }
    return fallback;
  }

  static Color hexToColor(String hex) {
    final normalized = normalizeHexColor(hex).replaceAll('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static Color priorityColor(String priority) {
    switch (normalizePriority(priority)) {
      case 'Высокий':
        return AppColors.error;
      case 'Средний':
        return AppColors.warning;
      case 'Низкий':
      default:
        return AppColors.success;
    }
  }

  static String quoteForToday() {
    return AppConstants.motivationalQuotes[DateTime.now().day %
        AppConstants.motivationalQuotes.length];
  }

  static int suggestedDurationForDifficulty(int difficulty) {
    switch (difficulty.clamp(1, 5)) {
      case 1:
        return 35;
      case 2:
        return 50;
      case 3:
        return 70;
      case 4:
        return 95;
      case 5:
      default:
        return 120;
    }
  }

  static String normalizeUserName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'JIHC Student') {
      return 'Студент JIHC';
    }
    if (trimmed == 'JIHC Demo Student') {
      return 'Демо-студент JIHC';
    }
    return trimmed;
  }

  static String normalizeStudentId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '[YOUR_STUDENT_ID]') {
      return AppConstants.developerStudentId;
    }
    return trimmed;
  }

  static String normalizeEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll('jihcfocus', 'flowday');
  }

  static bool isSportEventCategory(String category) {
    return normalizeEventCategory(category) == 'Спорт';
  }

  static bool isStudyEventCategory(String category) {
    return normalizeEventCategory(category) == 'Учёба';
  }

  static Map<String, dynamic> sanitizePlanBlock(
    DateTime date,
    Map<String, dynamic> block,
  ) {
    final category = normalizePlanCategory(block['category'] as String? ?? '');
    final title = (block['title'] as String? ?? '').trim();
    final start = DateTimeHelpers.parseTimeOnDate(
      date,
      block['startTime'] as String? ?? '00:00',
    );
    var end = DateTimeHelpers.parseTimeOnDate(
      date,
      block['endTime'] as String? ?? '00:00',
    );
    if (!end.isAfter(start)) {
      end = start.add(const Duration(minutes: 30));
    }
    return <String, dynamic>{
      'title': title.isEmpty ? defaultPlanBlockTitle(category) : title,
      'startTime': DateTimeHelpers.formatTime(start),
      'endTime': DateTimeHelpers.formatTime(end),
      'category': category,
      'color': normalizeHexColor(
        block['color'],
        fallback: categoryHex(category),
      ),
    };
  }

  static String defaultPlanBlockTitle(String category) {
    switch (normalizePlanCategory(category)) {
      case 'study':
        return 'Учебный блок';
      case 'sport':
        return 'Спорт';
      case 'rest':
        return 'Перерыв';
      case 'sleep':
        return 'Сон';
      default:
        return 'Личное время';
    }
  }

  static DateTime blockStart(DateTime date, Map<String, dynamic> block) {
    return DateTimeHelpers.parseTimeOnDate(
      date,
      block['startTime'] as String? ?? '00:00',
    );
  }

  static DateTime blockEnd(DateTime date, Map<String, dynamic> block) {
    final start = blockStart(date, block);
    var end = DateTimeHelpers.parseTimeOnDate(
      date,
      block['endTime'] as String? ?? '00:00',
    );
    if (!end.isAfter(start)) {
      end = start.add(const Duration(minutes: 30));
    }
    return end;
  }

  static int blockDurationMinutes(DateTime date, Map<String, dynamic> block) {
    return blockEnd(date, block).difference(blockStart(date, block)).inMinutes;
  }

  static List<Map<String, dynamic>> sortPlanBlocks(
    List<Map<String, dynamic>> blocks,
    DateTime date,
  ) {
    final sorted = blocks
        .map((block) => Map<String, dynamic>.from(block))
        .toList();
    sorted.sort((a, b) => blockStart(date, a).compareTo(blockStart(date, b)));
    return sorted;
  }
}
