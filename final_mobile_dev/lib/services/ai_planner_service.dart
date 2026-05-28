import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/date_time_helpers.dart';
import '../core/utils/planner_helpers.dart';
import '../models/day_plan_model.dart';
import '../models/event_model.dart';
import '../models/task_model.dart';

class AiPlannerService {
  AiPlannerService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _endpoint = 'https://api.anthropic.com/v1/messages';
  static const int _dayMinutes = 24 * 60;
  static const int _dayStartMinute = 7 * 60;
  static const int _dayEndMinute = 23 * 60;
  static const String _systemPrompt =
      'Ты ИИ-планировщик FlowDay для студентов JIHC. '
      'Составь расписание только для одной календарной даты. '
      'Обязательно включи все fixedEvents как неизменяемые блоки. '
      'Если спортивной активности нет, добавь один блок спорта на 30-60 минут. '
      'Между учебными блоками добавляй перерывы. '
      'Сон обязателен и должен быть покрыт двумя блоками: 00:00-07:00 и 23:00-23:59. '
      'Категория каждого блока может быть только одной из: study, sport, rest, sleep, personal. '
      'Для событий категорий Работа, Личное и Другое используй personal. '
      'Верни только сырой JSON-массив без пояснений, markdown и лишнего текста в формате '
      '[{"title":"...","startTime":"HH:MM","endTime":"HH:MM","category":"study|sport|rest|sleep|personal","color":"#hexcode"}].';

  Future<DayPlanModel> generatePlan({
    required DateTime date,
    required List<EventModel> events,
    required List<TaskModel> tasks,
  }) async {
    final normalizedDate = DateTimeHelpers.dateOnly(date);
    final fixedEvents = events.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final pendingTasks = tasks.where((task) => !task.isDone).toList()
      ..sort(_compareTasks);
    final apiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (apiKey.isEmpty) {
      return _fallbackPlan(
        date: normalizedDate,
        events: fixedEvents,
        tasks: pendingTasks,
      );
    }

    try {
      final payload = {
        'date': DateTimeHelpers.formatDate(normalizedDate),
        'fixedEvents': fixedEvents
            .map(
              (event) => {
                'title': event.title,
                'startTime': DateTimeHelpers.formatTime(event.startTime),
                'endTime': DateTimeHelpers.formatTime(event.endTime),
                'category': PlannerHelpers.planCategoryFromEventCategory(
                  event.category,
                ),
                'originalCategory': event.category,
                'color': PlannerHelpers.normalizeHexColor(
                  event.color,
                  fallback: PlannerHelpers.categoryHex(
                    PlannerHelpers.planCategoryFromEventCategory(
                      event.category,
                    ),
                  ),
                ),
              },
            )
            .toList(),
        'pendingTasks': pendingTasks
            .map(
              (task) => {
                'title': task.title,
                'deadline': DateTimeHelpers.formatDateTime(task.deadline),
                'priority': task.priority,
                'difficultyLevel': task.difficultyLevel,
              },
            )
            .toList(),
      };

      final response = await _client.post(
        Uri.parse(_endpoint),
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': AppConstants.anthropicModel,
          'max_tokens': 1400,
          'temperature': 0.2,
          'system': _systemPrompt,
          'messages': [
            {'role': 'user', 'content': jsonEncode(payload)},
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackPlan(
          date: normalizedDate,
          events: fixedEvents,
          tasks: pendingTasks,
        );
      }

      final aiBlocks = _decodeAiBlocks(normalizedDate, response.body);
      return _buildPlan(
        date: normalizedDate,
        events: fixedEvents,
        tasks: pendingTasks,
        aiBlocks: aiBlocks,
      );
    } catch (_) {
      return _fallbackPlan(
        date: normalizedDate,
        events: fixedEvents,
        tasks: pendingTasks,
      );
    }
  }

  DayPlanModel _fallbackPlan({
    required DateTime date,
    required List<EventModel> events,
    required List<TaskModel> tasks,
  }) {
    return _buildPlan(
      date: date,
      events: events,
      tasks: tasks,
      aiBlocks: const <Map<String, dynamic>>[],
    );
  }

  DayPlanModel _buildPlan({
    required DateTime date,
    required List<EventModel> events,
    required List<TaskModel> tasks,
    required List<Map<String, dynamic>> aiBlocks,
  }) {
    var blocks = <_ScheduledBlock>[
      ..._sleepBlocks(),
      ...events.map(_eventToBlock),
      ...aiBlocks.map((block) => _ScheduledBlock.fromMap(block, priority: 1)),
    ];

    blocks = _mergeBlocks(blocks);
    blocks = _ensureSportBlock(blocks, events);
    blocks = _ensureTaskBlocks(blocks, tasks);
    blocks = _fillGaps(blocks);
    blocks = _ensureRestBetweenStudies(blocks);
    blocks = _mergeBlocks(blocks);

    return DayPlanModel(
      date: date,
      blocks: blocks.map((block) => block.toMap()).toList(),
    );
  }

  List<Map<String, dynamic>> _decodeAiBlocks(DateTime date, String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final content = decoded['content'] as List<dynamic>? ?? <dynamic>[];
    final rawText = content
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['type'] == 'text')
        .map((item) => item['text'] as String? ?? '')
        .join('\n');
    final jsonArray = _extractJsonArray(rawText);
    final parsed = jsonDecode(jsonArray) as List<dynamic>;
    return parsed
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => PlannerHelpers.sanitizePlanBlock(
            date,
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  String _extractJsonArray(String raw) {
    final trimmed = raw.trim();
    final fenceFree = trimmed
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    final start = fenceFree.indexOf('[');
    final end = fenceFree.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) {
      return '[]';
    }
    return fenceFree.substring(start, end + 1);
  }

  List<_ScheduledBlock> _sleepBlocks() {
    return const <_ScheduledBlock>[
      _ScheduledBlock(
        title: 'Сон',
        startMinute: 0,
        endMinute: _dayStartMinute,
        category: 'sleep',
        color: '#560BAD',
        priority: 2,
      ),
      _ScheduledBlock(
        title: 'Сон',
        startMinute: _dayEndMinute,
        endMinute: _dayMinutes,
        category: 'sleep',
        color: '#560BAD',
        priority: 2,
      ),
    ];
  }

  _ScheduledBlock _eventToBlock(EventModel event) {
    return _ScheduledBlock(
      title: event.title,
      startMinute: DateTimeHelpers.minutesOfDay(event.startTime),
      endMinute: max(
        DateTimeHelpers.minutesOfDay(event.endTime),
        DateTimeHelpers.minutesOfDay(event.startTime) + 15,
      ),
      category: PlannerHelpers.planCategoryFromEventCategory(event.category),
      color: PlannerHelpers.normalizeHexColor(
        event.color,
        fallback: PlannerHelpers.categoryHex(
          PlannerHelpers.planCategoryFromEventCategory(event.category),
        ),
      ),
      priority: 3,
    );
  }

  List<_ScheduledBlock> _mergeBlocks(List<_ScheduledBlock> blocks) {
    final timeline = List<_ScheduledBlock?>.filled(_dayMinutes, null);
    final normalized = blocks.where((block) => block.duration >= 10).toList()
      ..sort((a, b) {
        final startCompare = a.startMinute.compareTo(b.startMinute);
        if (startCompare != 0) {
          return startCompare;
        }
        return a.priority.compareTo(b.priority);
      });

    for (final block in normalized) {
      final start = block.startMinute.clamp(0, _dayMinutes - 1);
      final end = block.endMinute.clamp(start + 1, _dayMinutes);
      for (var minute = start; minute < end; minute++) {
        final current = timeline[minute];
        if (current == null || block.priority >= current.priority) {
          timeline[minute] = block;
        }
      }
    }

    final merged = <_ScheduledBlock>[];
    _ScheduledBlock? active;
    var segmentStart = 0;
    for (var minute = 0; minute <= _dayMinutes; minute++) {
      final current = minute < _dayMinutes ? timeline[minute] : null;
      if (!_sameSignature(active, current)) {
        if (active != null && minute - segmentStart >= 10) {
          merged.add(
            active.copyWith(startMinute: segmentStart, endMinute: minute),
          );
        }
        active = current;
        segmentStart = minute;
      }
    }
    merged.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    return merged;
  }

  bool _sameSignature(_ScheduledBlock? a, _ScheduledBlock? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.title == b.title &&
        a.category == b.category &&
        a.color == b.color &&
        a.priority == b.priority;
  }

  List<_ScheduledBlock> _ensureSportBlock(
    List<_ScheduledBlock> blocks,
    List<EventModel> events,
  ) {
    final hasSport =
        blocks.any((block) => block.category == 'sport') ||
        events.any(
          (event) => PlannerHelpers.isSportEventCategory(event.category),
        );
    if (hasSport) {
      return blocks;
    }
    final gaps = _gaps(blocks, _dayStartMinute, _dayEndMinute);
    final preferred = gaps.where((gap) => gap.end - gap.start >= 30).toList()
      ..sort((a, b) {
        final aScore = a.start >= 16 * 60 ? 0 : 1;
        final bScore = b.start >= 16 * 60 ? 0 : 1;
        if (aScore != bScore) {
          return aScore.compareTo(bScore);
        }
        return (b.end - b.start).compareTo(a.end - a.start);
      });
    if (preferred.isEmpty) {
      return blocks;
    }
    final gap = preferred.first;
    final duration = min(45, gap.end - gap.start);
    return _mergeBlocks([
      ...blocks,
      _ScheduledBlock(
        title: 'Спорт',
        startMinute: gap.start,
        endMinute: gap.start + duration,
        category: 'sport',
        color: PlannerHelpers.categoryHex('sport'),
        priority: 1,
      ),
    ]);
  }

  List<_ScheduledBlock> _ensureTaskBlocks(
    List<_ScheduledBlock> blocks,
    List<TaskModel> tasks,
  ) {
    final scheduledTitles = blocks
        .where((block) => block.category == 'study')
        .map((block) => _normalizeTitle(block.title))
        .toSet();
    final queue =
        tasks
            .where(
              (task) => !scheduledTitles.contains(_normalizeTitle(task.title)),
            )
            .toList()
          ..sort(_compareTasks);
    if (queue.isEmpty) {
      return blocks;
    }
    final additions = <_ScheduledBlock>[];
    for (final gap in _gaps(blocks, _dayStartMinute, _dayEndMinute)) {
      var cursor = gap.start;
      while (queue.isNotEmpty && gap.end - cursor >= 30) {
        final task = queue.removeAt(0);
        final duration = min(
          PlannerHelpers.suggestedDurationForDifficulty(task.difficultyLevel),
          gap.end - cursor,
        );
        if (duration < 30) {
          queue.insert(0, task);
          break;
        }
        additions.add(
          _ScheduledBlock(
            title: task.title,
            startMinute: cursor,
            endMinute: cursor + duration,
            category: 'study',
            color: PlannerHelpers.categoryHex('study'),
            priority: 1,
          ),
        );
        cursor += duration;
        if (queue.isNotEmpty && gap.end - cursor >= 15) {
          additions.add(
            _ScheduledBlock(
              title: 'Перерыв',
              startMinute: cursor,
              endMinute: cursor + 15,
              category: 'rest',
              color: PlannerHelpers.categoryHex('rest'),
              priority: 1,
            ),
          );
          cursor += 15;
        }
      }
      if (queue.isEmpty) {
        break;
      }
    }
    if (additions.isEmpty) {
      return blocks;
    }
    return _mergeBlocks([...blocks, ...additions]);
  }

  List<_ScheduledBlock> _fillGaps(List<_ScheduledBlock> blocks) {
    final additions = <_ScheduledBlock>[];
    final sorted = blocks.toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    for (final gap in _gaps(sorted, _dayStartMinute, _dayEndMinute)) {
      final duration = gap.end - gap.start;
      if (duration < 15) {
        continue;
      }
      final previous = sorted.lastWhere(
        (block) => block.endMinute <= gap.start,
        orElse: () => const _ScheduledBlock(
          title: '',
          startMinute: 0,
          endMinute: 0,
          category: 'personal',
          color: '#B5179E',
          priority: 0,
        ),
      );
      final next = sorted.firstWhere(
        (block) => block.startMinute >= gap.end,
        orElse: () => const _ScheduledBlock(
          title: '',
          startMinute: 0,
          endMinute: 0,
          category: 'personal',
          color: '#B5179E',
          priority: 0,
        ),
      );
      final isRestGap =
          previous.category == 'study' || next.category == 'study';
      final category = isRestGap ? 'rest' : 'personal';
      additions.add(
        _ScheduledBlock(
          title: isRestGap ? 'Перерыв' : 'Личное время',
          startMinute: gap.start,
          endMinute: gap.end,
          category: category,
          color: PlannerHelpers.categoryHex(category),
          priority: 0,
        ),
      );
    }
    if (additions.isEmpty) {
      return blocks;
    }
    return _mergeBlocks([...blocks, ...additions]);
  }

  List<_ScheduledBlock> _ensureRestBetweenStudies(
    List<_ScheduledBlock> blocks,
  ) {
    final sorted = blocks.toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final updated = <_ScheduledBlock>[];
    for (var index = 0; index < sorted.length; index++) {
      final current = sorted[index];
      final previous = index > 0 ? sorted[index - 1] : null;
      final next = index < sorted.length - 1 ? sorted[index + 1] : null;
      if (current.category == 'personal' &&
          current.duration <= 30 &&
          previous?.category == 'study' &&
          next?.category == 'study') {
        updated.add(
          current.copyWith(
            title: 'Перерыв',
            category: 'rest',
            color: PlannerHelpers.categoryHex('rest'),
          ),
        );
      } else {
        updated.add(current);
      }
    }
    return updated;
  }

  List<({int start, int end})> _gaps(
    List<_ScheduledBlock> blocks,
    int startMinute,
    int endMinute,
  ) {
    final occupied =
        blocks
            .where(
              (block) =>
                  block.endMinute > startMinute &&
                  block.startMinute < endMinute,
            )
            .toList()
          ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final gaps = <({int start, int end})>[];
    var cursor = startMinute;
    for (final block in occupied) {
      final start = block.startMinute.clamp(startMinute, endMinute);
      final end = block.endMinute.clamp(startMinute, endMinute);
      if (start > cursor) {
        gaps.add((start: cursor, end: start));
      }
      cursor = max(cursor, end);
    }
    if (cursor < endMinute) {
      gaps.add((start: cursor, end: endMinute));
    }
    return gaps;
  }

  int _compareTasks(TaskModel a, TaskModel b) {
    const rank = {'Высокий': 0, 'Средний': 1, 'Низкий': 2};
    final priorityCompare = (rank[a.priority] ?? 9).compareTo(
      rank[b.priority] ?? 9,
    );
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return a.deadline.compareTo(b.deadline);
  }

  String _normalizeTitle(String value) {
    return value.trim().toLowerCase();
  }
}

class _ScheduledBlock {
  const _ScheduledBlock({
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.category,
    required this.color,
    required this.priority,
  });

  factory _ScheduledBlock.fromMap(
    Map<String, dynamic> map, {
    required int priority,
  }) {
    final startText = map['startTime'] as String? ?? '00:00';
    final endText = map['endTime'] as String? ?? '00:00';
    final startParts = startText.split(':');
    final endParts = endText.split(':');
    final startMinute =
        ((int.tryParse(startParts.first) ?? 0) * 60) +
        (startParts.length > 1 ? int.tryParse(startParts[1]) ?? 0 : 0);
    var endMinute =
        ((int.tryParse(endParts.first) ?? 0) * 60) +
        (endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0);
    if (endMinute <= startMinute) {
      endMinute = min(startMinute + 30, AiPlannerService._dayMinutes);
    }
    return _ScheduledBlock(
      title: map['title'] as String? ?? '',
      startMinute: startMinute,
      endMinute: endMinute,
      category: PlannerHelpers.normalizePlanCategory(
        map['category'] as String? ?? '',
      ),
      color: PlannerHelpers.normalizeHexColor(
        map['color'],
        fallback: PlannerHelpers.categoryHex(
          map['category'] as String? ?? 'personal',
        ),
      ),
      priority: priority,
    );
  }

  final String title;
  final int startMinute;
  final int endMinute;
  final String category;
  final String color;
  final int priority;

  int get duration => endMinute - startMinute;

  _ScheduledBlock copyWith({
    String? title,
    int? startMinute,
    int? endMinute,
    String? category,
    String? color,
    int? priority,
  }) {
    return _ScheduledBlock(
      title: title ?? this.title,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      category: category ?? this.category,
      color: color ?? this.color,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startTime': _formatMinute(startMinute),
      'endTime': _formatMinute(endMinute),
      'category': category,
      'color': color,
    };
  }

  String _formatMinute(int minute) {
    final clamped = minute >= AiPlannerService._dayMinutes
        ? AiPlannerService._dayMinutes - 1
        : minute.clamp(0, AiPlannerService._dayMinutes - 1);
    final hours = clamped ~/ 60;
    final minutes = clamped % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
