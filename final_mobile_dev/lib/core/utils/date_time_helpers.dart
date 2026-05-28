import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeHelpers {
  const DateTimeHelpers._();

  static DateTime parseDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String formatDate(DateTime value) {
    return DateFormat('dd.MM.yyyy').format(value.toLocal());
  }

  static String formatLongDate(DateTime value) {
    return DateFormat('d MMMM, EEEE', 'ru_RU').format(value.toLocal());
  }

  static String formatDateTime(DateTime value) {
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }

  static String formatTime(DateTime value) {
    return DateFormat('HH:mm').format(value.toLocal());
  }

  static String formatMonthDay(DateTime value) {
    return DateFormat('dd.MM').format(value.toLocal());
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime startOfDay(DateTime value) {
    return dateOnly(value);
  }

  static DateTime endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59);
  }

  static DateTime combineDateAndTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime combineDateAndTimeOfDay(DateTime date, TimeOfDay time) {
    return combineDateAndTime(date, time.hour, time.minute);
  }

  static DateTime parseTimeOnDate(DateTime date, String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return combineDateAndTime(date, hour, minute);
  }

  static int minutesOfDay(DateTime value) => value.hour * 60 + value.minute;

  static DateTime fromMinutesOfDay(DateTime date, int minutes) {
    return combineDateAndTime(date, minutes ~/ 60, minutes % 60);
  }

  static String dayKey(DateTime date) {
    final normalized = dateOnly(date);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  static List<DateTime> last7Days() {
    final today = dateOnly(DateTime.now());
    return List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
  }
}
