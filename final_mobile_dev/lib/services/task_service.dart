import 'dart:async';

import '../models/task_model.dart';
import 'preferences_service.dart';

class TaskService {
  TaskService({required PreferencesService preferencesService})
    : _preferencesService = preferencesService;

  final PreferencesService _preferencesService;
  final StreamController<String> _localChanges =
      StreamController<String>.broadcast();

  Stream<List<TaskModel>> watchTasks(String uid) {
    if (uid.isEmpty) {
      return Stream<List<TaskModel>>.value(<TaskModel>[]);
    }
    return _watchLocal(uid);
  }

  Future<List<TaskModel>> getTasks(String uid) async {
    try {
      return _preferencesService
          .getList(_storageKey(uid))
          .map((item) => TaskModel.fromMap(item['id'] as String? ?? '', item))
          .toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
    } catch (_) {
      rethrow;
    }
  }

  Future<TaskModel?> getTaskById(String uid, String taskId) async {
    final tasks = await getTasks(uid);
    for (final task in tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<void> addTask(String uid, TaskModel task) async {
    try {
      final tasks = await getTasks(uid);
      tasks.add(task);
      await _saveLocal(uid, tasks);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateTask(String uid, TaskModel task) async {
    try {
      final tasks = await getTasks(uid);
      final updated = tasks
          .map((item) => item.id == task.id ? task : item)
          .toList();
      await _saveLocal(uid, updated);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteTask(String uid, String taskId) async {
    try {
      final tasks = await getTasks(uid);
      tasks.removeWhere((item) => item.id == taskId);
      await _saveLocal(uid, tasks);
    } catch (_) {
      rethrow;
    }
  }

  Stream<List<TaskModel>> _watchLocal(String uid) async* {
    yield await getTasks(uid);
    yield* _localChanges.stream
        .where((changedUid) => changedUid == uid)
        .asyncMap((_) => getTasks(uid));
  }

  Future<void> _saveLocal(String uid, List<TaskModel> tasks) async {
    await _preferencesService.setList(
      _storageKey(uid),
      tasks
          .map((item) => <String, dynamic>{'id': item.id, ...item.toMap()})
          .toList(),
    );
    _localChanges.add(uid);
  }

  String _storageKey(String uid) => 'flowday_tasks_$uid';
}
