import 'dart:async';

import '../models/event_model.dart';
import 'preferences_service.dart';

class EventService {
  EventService({required PreferencesService preferencesService})
    : _preferencesService = preferencesService;

  final PreferencesService _preferencesService;
  final StreamController<String> _localChanges =
      StreamController<String>.broadcast();

  Stream<List<EventModel>> watchEvents(String uid) {
    if (uid.isEmpty) {
      return Stream<List<EventModel>>.value(<EventModel>[]);
    }
    return _watchLocal(uid);
  }

  Future<List<EventModel>> getEvents(String uid) async {
    try {
      return _preferencesService
          .getList(_storageKey(uid))
          .map((item) => EventModel.fromMap(item['id'] as String? ?? '', item))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
      rethrow;
    }
  }

  Future<EventModel?> getEventById(String uid, String eventId) async {
    final events = await getEvents(uid);
    for (final event in events) {
      if (event.id == eventId) {
        return event;
      }
    }
    return null;
  }

  Future<void> addEvent(String uid, EventModel event) async {
    try {
      final events = await getEvents(uid);
      events.add(event);
      await _saveLocal(uid, events);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateEvent(String uid, EventModel event) async {
    try {
      final events = await getEvents(uid);
      final updated = events
          .map((item) => item.id == event.id ? event : item)
          .toList();
      await _saveLocal(uid, updated);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String uid, String eventId) async {
    try {
      final events = await getEvents(uid);
      events.removeWhere((item) => item.id == eventId);
      await _saveLocal(uid, events);
    } catch (_) {
      rethrow;
    }
  }

  Stream<List<EventModel>> _watchLocal(String uid) async* {
    yield await getEvents(uid);
    yield* _localChanges.stream
        .where((changedUid) => changedUid == uid)
        .asyncMap((_) => getEvents(uid));
  }

  Future<void> _saveLocal(String uid, List<EventModel> events) async {
    await _preferencesService.setList(
      _storageKey(uid),
      events
          .map((item) => <String, dynamic>{'id': item.id, ...item.toMap()})
          .toList(),
    );
    _localChanges.add(uid);
  }

  String _storageKey(String uid) => 'flowday_events_$uid';
}
