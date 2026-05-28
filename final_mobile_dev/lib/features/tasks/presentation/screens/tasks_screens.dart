import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/date_time_helpers.dart';
import '../../../../core/utils/planner_helpers.dart';
import '../../../../models/task_model.dart';
import '../../../../providers/task_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_scaffold.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _priorityFilter = 'Все';
  String _statusFilter = 'Все';
  bool _isOpeningShortcut = false;

  Future<void> _openTaskShortcut(String route) async {
    if (_isOpeningShortcut) {
      return;
    }
    setState(() => _isOpeningShortcut = true);
    try {
      await context.push(route);
    } finally {
      if (mounted) {
        setState(() => _isOpeningShortcut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: 'Задачи',
      actions: [
        IconButton(
          onPressed: _isOpeningShortcut
              ? null
              : () => _openTaskShortcut(AppRoutes.priorityTasks),
          icon: const Icon(Icons.priority_high_rounded),
        ),
        IconButton(
          onPressed: _isOpeningShortcut
              ? null
              : () => _openTaskShortcut(AppRoutes.completedTasks),
          icon: const Icon(Icons.done_all_rounded),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTask),
        child: const Icon(Icons.add_rounded),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: provider.tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data ?? <TaskModel>[];
          final filtered = provider.filterTasks(
            tasks,
            priority: _priorityFilter,
            status: _statusFilter,
          );
          final completed = tasks.where((task) => task.isDone).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 148,
                ),
                children: [
                  _TaskMetric(
                    title: 'Всего',
                    value: tasks.length.toString(),
                    subtitle: 'задач в системе',
                    icon: Icons.list_alt_rounded,
                  ),
                  _TaskMetric(
                    title: 'Активные',
                    value: tasks
                        .where((task) => !task.isDone)
                        .length
                        .toString(),
                    subtitle: 'ещё не завершены',
                    icon: Icons.pending_actions_rounded,
                  ),
                  _TaskMetric(
                    title: 'Выполнены',
                    value: completed.toString(),
                    subtitle: 'закрытых задач',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Приоритет',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Все', _priorityFilter, (value) {
                      setState(() => _priorityFilter = value);
                    }),
                    const SizedBox(width: 8),
                    ...AppConstants.taskPriorities.map(
                      (priority) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(priority, _priorityFilter, (
                          value,
                        ) {
                          setState(() => _priorityFilter = value);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Статус',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Все', _statusFilter, (value) {
                      setState(() => _statusFilter = value);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Активные', _statusFilter, (value) {
                      setState(() => _statusFilter = value);
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('Выполненные', _statusFilter, (value) {
                      setState(() => _statusFilter = value);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.only(bottom: 96),
                        children: [
                          EmptyStateCard(
                            title: 'Задачи не найдены',
                            subtitle:
                                'Попробуй изменить фильтры или добавь новую задачу с дедлайном.',
                            icon: Icons.task_outlined,
                            action: FilledButton(
                              onPressed: () => context.push(AppRoutes.addTask),
                              child: const Text('Добавить задачу'),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          return Dismissible(
                            key: ValueKey(task.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(Icons.delete_outline_rounded),
                            ),
                            onDismissed: (_) async {
                              await provider.deleteTask(task.id);
                              if (!context.mounted) {
                                return;
                              }
                              showAppSnackBar(context, 'Задача удалена.');
                            },
                            child: FlowCard(
                              onTap: () => context.push(
                                AppRoutes.taskDetail,
                                extra: task,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: task.isDone,
                                    onChanged: (value) => provider.toggleDone(
                                      task,
                                      value ?? false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                decoration: task.isDone
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Дедлайн: ${DateTimeHelpers.formatDateTime(task.deadline)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: PlannerHelpers.priorityColor(
                                            task.priority,
                                          ).withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          task.priority,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: PlannerHelpers.priorityColor(
                                              task.priority,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('${task.difficultyLevel}/5'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String current,
    ValueChanged<String> onSelected,
  ) {
    return ChoiceChip(
      selected: current == label,
      label: Text(label),
      onSelected: (_) => onSelected(label),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TaskFormScreen(title: 'Новая задача');
  }
}

class EditTaskScreen extends StatelessWidget {
  const EditTaskScreen({super.key, required this.task});

  final TaskModel? task;

  @override
  Widget build(BuildContext context) {
    return _TaskFormScreen(
      title: 'Редактировать задачу',
      initialTask: task,
      isEditing: true,
    );
  }
}

class _TaskFormScreen extends StatefulWidget {
  const _TaskFormScreen({
    required this.title,
    this.initialTask,
    this.isEditing = false,
  });

  final String title;
  final TaskModel? initialTask;
  final bool isEditing;

  @override
  State<_TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<_TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  late DateTime _deadline;
  late String _priority;
  late double _difficulty;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController.text = task?.title ?? '';
    _deadline = task?.deadline ?? DateTime.now().add(const Duration(days: 1));
    _priority = task?.priority ?? 'Средний';
    _difficulty = (task?.difficultyLevel ?? 3).toDouble();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (pickedTime == null) {
      return;
    }
    setState(() {
      _deadline = DateTimeHelpers.combineDateAndTimeOfDay(
        pickedDate,
        pickedTime,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final provider = context.read<TaskProvider>();
      if (widget.isEditing && widget.initialTask != null) {
        await provider.updateTask(
          widget.initialTask!.copyWith(
            title: _titleController.text.trim(),
            deadline: _deadline,
            priority: _priority,
            difficultyLevel: _difficulty.round(),
          ),
        );
      } else {
        await provider.addTask(
          title: _titleController.text.trim(),
          deadline: _deadline,
          priority: _priority,
          difficultyLevel: _difficulty.round(),
        );
      }
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Задача сохранена.');
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, _taskSaveError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: widget.title,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  prefixIcon: Icon(Icons.task_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Введите понятное название задачи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FlowCard(
                onTap: _pickDeadline,
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Дедлайн',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(DateTimeHelpers.formatDateTime(_deadline)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Приоритет',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.taskPriorities.map((priority) {
                  return ChoiceChip(
                    selected: _priority == priority,
                    label: Text(priority),
                    onSelected: (_) => setState(() => _priority = priority),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Сложность: ${_difficulty.round()} / 5',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _difficulty,
                min: 1,
                max: 5,
                divisions: 4,
                label: _difficulty.round().toString(),
                onChanged: (value) => setState(() => _difficulty = value),
              ),
              const SizedBox(height: 24),
              FlowButton(
                label: widget.isEditing
                    ? 'Сохранить изменения'
                    : 'Создать задачу',
                isLoading: provider.isBusy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskModel? task;

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return const FlowScaffold(
        title: 'Задача',
        padding: EdgeInsets.all(24),
        body: EmptyStateCard(
          title: 'Задача не найдена',
          subtitle: 'Не удалось открыть выбранную задачу.',
          icon: Icons.error_outline_rounded,
        ),
      );
    }
    final provider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: 'Задача',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.editTask, extra: task),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: Column(
        children: [
          FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _TaskInfoRow(
                  title: 'Дедлайн',
                  value: DateTimeHelpers.formatDateTime(task!.deadline),
                ),
                _TaskInfoRow(title: 'Приоритет', value: task!.priority),
                _TaskInfoRow(
                  title: 'Сложность',
                  value: '${task!.difficultyLevel} / 5',
                ),
                _TaskInfoRow(
                  title: 'Статус',
                  value: task!.isDone ? 'Выполнена' : 'Активна',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FlowButton(
            label: task!.isDone ? 'Вернуть в активные' : 'Отметить выполненной',
            isLoading: provider.isBusy,
            onPressed: () async {
              await context.read<TaskProvider>().toggleDone(
                task!,
                !task!.isDone,
              );
              if (!context.mounted) {
                return;
              }
              showAppSnackBar(
                context,
                task!.isDone
                    ? 'Задача снова активна.'
                    : 'Задача отмечена как выполненная.',
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<TaskProvider>().deleteTask(task!.id);
              if (!context.mounted) {
                return;
              }
              showAppSnackBar(context, 'Задача удалена.');
              context.pop();
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Удалить задачу'),
          ),
        ],
      ),
    );
  }
}

class PriorityTasksScreen extends StatelessWidget {
  const PriorityTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: 'Высокий приоритет',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: provider.tasksStream,
        builder: (context, snapshot) {
          final tasks =
              snapshot.data
                  ?.where((task) => task.priority == 'Высокий' && !task.isDone)
                  .toList() ??
              <TaskModel>[];
          if (tasks.isEmpty) {
            return const EmptyStateCard(
              title: 'Срочных задач нет',
              subtitle: 'Список высокого приоритета сейчас пуст.',
              icon: Icons.priority_high_rounded,
            );
          }
          return ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => FlowCard(
              onTap: () =>
                  context.push(AppRoutes.taskDetail, extra: tasks[index]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tasks[index].title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateTimeHelpers.formatDateTime(tasks[index].deadline),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: 'Выполненные задачи',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: provider.tasksStream,
        builder: (context, snapshot) {
          final tasks =
              (snapshot.data?.where((task) => task.isDone).toList()
                ?..sort((a, b) => b.deadline.compareTo(a.deadline))) ??
              <TaskModel>[];
          if (tasks.isEmpty) {
            return const EmptyStateCard(
              title: 'Пока ничего не завершено',
              subtitle:
                  'Здесь появятся задачи, которые ты отметил как выполненные.',
              icon: Icons.done_all_rounded,
            );
          }
          return ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => FlowCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tasks[index].title),
                        const SizedBox(height: 4),
                        Text(
                          DateTimeHelpers.formatDateTime(tasks[index].deadline),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskInfoRow extends StatelessWidget {
  const _TaskInfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMetric extends StatelessWidget {
  const _TaskMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.tertiary, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.82),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String _taskSaveError(Object error) {
  if (error is ArgumentError || error is StateError) {
    return error.toString().replaceFirst(
      RegExp(r'^(Invalid argument\(s\)|Bad state): '),
      '',
    );
  }
  return 'Не удалось сохранить задачу.';
}
