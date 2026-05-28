import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import 'auth_provider.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required TaskService service,
    required AuthProvider authProvider,
  }) : _service = service,
       _authProvider = authProvider {
    _userId = _authProvider.user?.id;
    _authProvider.addListener(_syncUser);
  }

  final TaskService _service;
  final AuthProvider _authProvider;
  final Uuid _uuid = const Uuid();

  String? _userId;
  bool _busy = false;
  String? _errorMessage;

  bool get isBusy => _busy;
  String? get errorMessage => _errorMessage;
  String get _safeUserId => _userId ?? '';
  Stream<List<TaskModel>> get tasksStream => _service.watchTasks(_safeUserId);

  Future<void> addTask({
    required String title,
    required DateTime deadline,
    required String priority,
    required int difficultyLevel,
  }) async {
    if (_userId == null) {
      throw StateError('Войдите в аккаунт, чтобы сохранить задачу.');
    }
    _validateTask(
      title: title,
      deadline: deadline,
      priority: priority,
      difficultyLevel: difficultyLevel,
    );
    await _run(
      () => _service.addTask(
        _userId!,
        TaskModel(
          id: _uuid.v4(),
          title: title,
          deadline: deadline,
          priority: priority,
          isDone: false,
          difficultyLevel: difficultyLevel,
        ),
      ),
    );
  }

  Future<void> updateTask(TaskModel task) async {
    if (_userId == null) {
      throw StateError('Войдите в аккаунт, чтобы сохранить задачу.');
    }
    _validateTask(
      title: task.title,
      deadline: task.deadline,
      priority: task.priority,
      difficultyLevel: task.difficultyLevel,
    );
    await _run(() => _service.updateTask(_userId!, task));
  }

  Future<void> toggleDone(TaskModel task, bool value) async {
    await updateTask(task.copyWith(isDone: value));
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) {
      throw StateError('Войдите в аккаунт, чтобы удалить задачу.');
    }
    await _run(() => _service.deleteTask(_userId!, taskId));
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    if (_userId == null) {
      return null;
    }
    return _service.getTaskById(_userId!, taskId);
  }

  List<TaskModel> filterByPriority(List<TaskModel> tasks, String priority) {
    if (priority == 'Все') {
      return tasks;
    }
    return tasks.where((task) => task.priority == priority).toList();
  }

  List<TaskModel> filterTasks(
    List<TaskModel> tasks, {
    required String priority,
    required String status,
  }) {
    var filtered = filterByPriority(tasks, priority);
    switch (status) {
      case 'Активные':
        filtered = filtered.where((task) => !task.isDone).toList();
        break;
      case 'Выполненные':
        filtered = filtered.where((task) => task.isDone).toList();
        break;
      default:
        break;
    }
    filtered.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return a.deadline.compareTo(b.deadline);
    });
    return filtered;
  }

  void _validateTask({
    required String title,
    required DateTime deadline,
    required String priority,
    required int difficultyLevel,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Введите название задачи.');
    }
    if (deadline.year < 2000 || deadline.year > 3000) {
      throw ArgumentError('Выберите корректный дедлайн.');
    }
    if (priority.trim().isEmpty) {
      throw ArgumentError('Выберите приоритет задачи.');
    }
    if (difficultyLevel < 1 || difficultyLevel > 5) {
      throw ArgumentError('Сложность должна быть от 1 до 5.');
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
