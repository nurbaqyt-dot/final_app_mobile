import 'package:flutter/material.dart';

import '../core/utils/date_time_helpers.dart';
import '../models/day_plan_model.dart';
import '../models/event_model.dart';
import '../models/task_model.dart';
import '../services/ai_planner_service.dart';

class PlanProvider extends ChangeNotifier {
  PlanProvider({required AiPlannerService service}) : _service = service;

  final AiPlannerService _service;
  final Map<String, DayPlanModel> _plansByDate = <String, DayPlanModel>{};

  DayPlanModel? _currentPlan;
  Map<String, dynamic>? _selectedBlock;
  DateTime _selectedDate = DateTimeHelpers.dateOnly(DateTime.now());
  bool _busy = false;
  String? _statusMessage;
  String? _errorMessage;

  DayPlanModel? get currentPlan => _currentPlan;
  Map<String, dynamic>? get selectedBlock => _selectedBlock;
  DateTime get selectedDate => _selectedDate;
  bool get isBusy => _busy;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;

  void setSelectedDate(DateTime value) {
    _selectedDate = DateTimeHelpers.dateOnly(value);
    _currentPlan = _plansByDate[_key(_selectedDate)];
    notifyListeners();
  }

  void selectBlock(Map<String, dynamic>? block) {
    _selectedBlock = block == null ? null : Map<String, dynamic>.from(block);
    notifyListeners();
  }

  Future<void> generatePlan({
    required List<EventModel> events,
    required List<TaskModel> tasks,
  }) async {
    _busy = true;
    _statusMessage = null;
    _errorMessage = null;
    notifyListeners();
    try {
      final plan = await _service.generatePlan(
        date: _selectedDate,
        events: events,
        tasks: tasks,
      );
      _currentPlan = plan;
      _plansByDate[_key(_selectedDate)] = plan;
      _statusMessage = 'План на день обновлён.';
    } catch (error) {
      _statusMessage = 'Не удалось построить план: $error';
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _key(DateTime date) => DateTimeHelpers.dayKey(date);
}
