import 'package:flutter/material.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'FlowDay';
  static const String developerName = 'Исмаилова';
  static const String developerStudentId = 'JIHC-2026-001';
  static const String college = 'JIHC';
  static const String primaryHex = '#7209B7';
  static const String accentHex = '#9D4EDD';
  static const String onboardingSeenKey = 'flowday_onboarding_seen';
  static const String demoUserKey = 'flowday_demo_user';
  static const String logoAsset = 'assets/images/jihc_logo.webp';
  static const String anthropicModel = 'claude-sonnet-4-20250514';

  static const List<Map<String, String>> onboardingPages = [
    {
      'title': 'План дня с ИИ',
      'subtitle':
          'FlowDay собирает пары, дедлайны и личные дела в одно умное расписание на каждый день.',
    },
    {
      'title': 'Меньше хаоса, больше ритма',
      'subtitle':
          'Добавляй фиксированные события и задачи, а ИИ найдёт окна для учёбы, спорта и отдыха.',
    },
    {
      'title': 'Продуктивность без перегруза',
      'subtitle':
          'Следи за прогрессом, закрывай задачи вовремя и сохраняй устойчивый учебный темп.',
    },
  ];

  static const List<String> eventCategories = [
    'Учёба',
    'Спорт',
    'Работа',
    'Отдых',
    'Личное',
    'Другое',
  ];

  static const List<String> taskPriorities = ['Высокий', 'Средний', 'Низкий'];

  static const List<String> planCategories = [
    'study',
    'sport',
    'rest',
    'sleep',
    'personal',
  ];

  static const List<String> motivationalQuotes = [
    'Хороший день начинается не со спешки, а с ясного плана.',
    'Когда время распределено с умом, учёба перестаёт быть хаосом.',
    'Один организованный день даёт больше, чем неделя откладывания.',
    'Сильный ритм строится из маленьких, но точных решений.',
    'Порядок в расписании освобождает место для настоящего фокуса.',
    'Лучший способ успеть главное — увидеть приоритеты заранее.',
  ];

  static const List<Color> presetColors = [
    Color(0xFF7209B7),
    Color(0xFF9D4EDD),
    Color(0xFF560BAD),
    Color(0xFFE0AAFF),
    Color(0xFFB5179E),
    Color(0xFF7B2CBF),
    Color(0xFFC77DFF),
    Color(0xFF1A0030),
  ];
}
