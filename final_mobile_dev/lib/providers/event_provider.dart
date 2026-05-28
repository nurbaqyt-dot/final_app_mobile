import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_time_helpers.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'auth_provider.dart';

class EventProvider extends ChangeNotifier {
  EventProvider({
    required EventService service,
    required AuthProvider authProvider,
  }) : _service = service,
       _authProvider = authProvider {
    _userId = _authProvider.user?.id;
    _authProvider.addListener(_syncUser);
  }

  final EventService _service;
  final AuthProvider _authProvider;
  final Uuid _uuid = const Uuid();

  String? _userId;
  bool _busy = false;
  String? _errorMessage;

  bool get isBusy => _busy;
  String? get errorMessage => _errorMessage;
  String get _safeUserId => _userId ?? '';
  Stream<List<EventModel>> get eventsStream =>
      _service.watchEvents(_safeUserId);

  Future<void> addEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    required String color,
  }) async {
    if (_userId == null) {
      throw StateError('Войдите в аккаунт, чтобы сохранить событие.');
    }
    _validateEvent(
      title: title,
      startTime: startTime,
      endTime: endTime,
      category: category,
      color: color,
    );
    await _run(
      () => _service.addEvent(
        _userId!,
        EventModel(
          id: _uuid.v4(),
          title: title,
          startTime: startTime,
          endTime: endTime,
          category: category,
          color: color,
        ),
      ),
    );
  }

  Future<void> updateEvent(EventModel event) async {
    if (_userId == null) {
      throw StateError('Войдите в аккаунт, чтобы сохранить событие.');
    }
    _validateEvent(
      title: event.title,
      startTime: event.startTime,
      endTime: event.endTime,
      category: event.category,
      color: event.color,
    );
    await _run(() => _service.updateEvent(_userId!, event));
  }

  Future<void> deleteEvent(String eventId) async {
    if (_userId == null) {
      throw StateError('Войдите в аккаунт, чтобы удалить событие.');
    }
    await _run(() => _service.deleteEvent(_userId!, eventId));
  }

  Future<EventModel?> getEventById(String eventId) async {
    if (_userId == null) {
      return null;
    }
    return _service.getEventById(_userId!, eventId);
  }

  List<EventModel> filterForDate(List<EventModel> events, DateTime date) {
    return events
        .where(
          (event) =>
              DateTimeHelpers.isSameDay(event.startTime, date) ||
              DateTimeHelpers.isSameDay(event.endTime, date),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _validateEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    required String color,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Введите название события.');
    }
    if (!endTime.isAfter(startTime)) {
      throw ArgumentError('Время окончания должно быть позже времени начала.');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('Выберите категорию события.');
    }
    if (color.trim().isEmpty) {
      throw ArgumentError('Выберите цвет события.');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _syncUser() {
    final nextUserId = _authProvider.user?.id;
    if (nextUserId != _userId) {
      _userId = nextUserId;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_syncUser);
    super.dispose();
  }
}
