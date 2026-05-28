import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/date_time_helpers.dart';
import '../../../../core/utils/planner_helpers.dart';
import '../../../../models/event_model.dart';
import '../../../../models/task_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/event_provider.dart';
import '../../../../providers/plan_provider.dart';
import '../../../../providers/task_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_logo.dart';
import '../../../../widgets/flow_scaffold.dart';
import '../../../../widgets/timeline_block_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final planProvider = context.watch<PlanProvider>();

    return FlowScaffold(
      title: 'Сегодня',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.morningBrief),
          icon: const Icon(Icons.wb_sunny_outlined),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.statistics),
          icon: const Icon(Icons.query_stats_rounded),
        ),
      ],
      body: Stack(
        children: [
          StreamBuilder<List<EventModel>>(
            stream: eventProvider.eventsStream,
            builder: (context, eventSnapshot) {
              final allEvents = eventSnapshot.data ?? <EventModel>[];
              final dayEvents = eventProvider.filterForDate(
                allEvents,
                planProvider.selectedDate,
              );
              return StreamBuilder<List<TaskModel>>(
                stream: taskProvider.tasksStream,
                builder: (context, taskSnapshot) {
                  final allTasks = taskSnapshot.data ?? <TaskModel>[];
                  final pendingTasks =
                      allTasks.where((task) => !task.isDone).toList()
                        ..sort((a, b) => a.deadline.compareTo(b.deadline));
                  final plan = planProvider.currentPlan;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 152),
                    children: [
                      FlowCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const FlowLogo(size: 60, showText: false),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Привет, ${auth.displayName.split(' ').first}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateTimeHelpers.formatLongDate(
                                          planProvider.selectedDate,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              PlannerHelpers.quoteForToday(),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            FlowButton(
                              label: 'Собрать план на день',
                              icon: Icons.auto_awesome_rounded,
                              isLoading: planProvider.isBusy,
                              onPressed: () => _generatePlan(
                                context,
                                dayEvents,
                                pendingTasks,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _pickDate(context),
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: const Text('Выбрать дату'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 148,
                            ),
                        children: [
                          _TodayMetric(
                            title: 'События',
                            value: dayEvents.length.toString(),
                            subtitle: 'на выбранный день',
                            icon: Icons.event_note_outlined,
                          ),
                          _TodayMetric(
                            title: 'Задачи',
                            value: pendingTasks.length.toString(),
                            subtitle: 'ожидают выполнения',
                            icon: Icons.task_alt_outlined,
                          ),
                          _TodayMetric(
                            title: 'Фокус',
                            value: plan == null
                                ? '0%'
                                : '${(plan.productivityPercent * 100).round()}%',
                            subtitle: 'по ИИ-плану',
                            icon: Icons.bolt_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Расписание дня',
                        actionLabel: plan == null ? null : 'Открыть экран',
                        onAction: plan == null
                            ? null
                            : () => context.push(AppRoutes.aiPlan),
                      ),
                      const SizedBox(height: 12),
                      if (plan == null)
                        const EmptyStateCard(
                          title: 'План ещё не создан',
                          subtitle:
                              'Добавь события и задачи, затем попроси FlowDay собрать сбалансированное расписание с учёбой, отдыхом и спортом.',
                          icon: Icons.auto_awesome_outlined,
                        )
                      else
                        ...plan.sortedBlocks.map(
                          (block) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TimelineBlockCard(
                              date: plan.date,
                              block: block,
                              onTap: () => context.push(
                                AppRoutes.aiPlanDetail,
                                extra: block,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Фиксированные события',
                        actionLabel: 'Все события',
                        onAction: () => context.go(AppRoutes.events),
                      ),
                      const SizedBox(height: 12),
                      if (dayEvents.isEmpty)
                        const EmptyStateCard(
                          title: 'На выбранную дату нет событий',
                          subtitle:
                              'Добавь пары, работу, спорт или личные встречи, чтобы ИИ строил более точный день.',
                          icon: Icons.event_busy_outlined,
                        )
                      else
                        ...dayEvents
                            .take(3)
                            .map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FlowCard(
                                  onTap: () => context.push(
                                    AppRoutes.eventDetail,
                                    extra: event,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: PlannerHelpers.hexToColor(
                                            event.color,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${DateTimeHelpers.formatTime(event.startTime)} - ${DateTimeHelpers.formatTime(event.endTime)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        event.category,
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
                              ),
                            ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Срочные задачи',
                        actionLabel: 'Все задачи',
                        onAction: () => context.go(AppRoutes.tasks),
                      ),
                      const SizedBox(height: 12),
                      if (pendingTasks.isEmpty)
                        const EmptyStateCard(
                          title: 'Нет активных задач',
                          subtitle:
                              'Когда появятся дедлайны, FlowDay подберёт для них свободные окна.',
                          icon: Icons.task_outlined,
                        )
                      else
                        ...pendingTasks
                            .take(4)
                            .map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FlowCard(
                                  onTap: () => context.push(
                                    AppRoutes.taskDetail,
                                    extra: task,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: PlannerHelpers.priorityColor(
                                            task.priority,
                                          ).withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.flag_rounded,
                                          color: PlannerHelpers.priorityColor(
                                            task.priority,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Дедлайн: ${DateTimeHelpers.formatDateTime(task.deadline)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            task.priority,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      PlannerHelpers.priorityColor(
                                                        task.priority,
                                                      ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${task.difficultyLevel}/5'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ],
                  );
                },
              );
            },
          ),
          if (planProvider.isBusy)
            const Positioned.fill(child: _LoadingOverlay()),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<PlanProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    provider.setSelectedDate(picked);
  }

  Future<void> _generatePlan(
    BuildContext context,
    List<EventModel> events,
    List<TaskModel> tasks,
  ) async {
    try {
      await context.read<PlanProvider>().generatePlan(
        events: events,
        tasks: tasks,
      );
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, 'План дня готов.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        'Не удалось собрать план на день.',
        isError: true,
      );
    }
  }
}

class AiPlanScreen extends StatelessWidget {
  const AiPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final plan = provider.currentPlan;
    return FlowScaffold(
      title: 'ИИ-план',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.plannerTips),
          icon: const Icon(Icons.tips_and_updates_outlined),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: plan == null
          ? const EmptyStateCard(
              title: 'План недоступен',
              subtitle:
                  'Вернись на экран «Сегодня» и попроси FlowDay собрать расписание на день.',
              icon: Icons.auto_awesome_outlined,
            )
          : ListView(
              children: [
                FlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTimeHelpers.formatLongDate(plan.date),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Продуктивная часть дня: ${(plan.productivityPercent * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...plan.sortedBlocks.map(
                  (block) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TimelineBlockCard(
                      date: plan.date,
                      block: block,
                      onTap: () =>
                          context.push(AppRoutes.aiPlanDetail, extra: block),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class AiPlanDetailScreen extends StatelessWidget {
  const AiPlanDetailScreen({super.key, required this.block});

  final Map<String, dynamic>? block;

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>().currentPlan;
    final date = plan?.date ?? context.watch<PlanProvider>().selectedDate;
    if (block == null) {
      return const FlowScaffold(
        title: 'Блок плана',
        padding: EdgeInsets.all(24),
        body: EmptyStateCard(
          title: 'Блок не найден',
          subtitle: 'Не удалось открыть детали выбранного блока.',
          icon: Icons.error_outline_rounded,
        ),
      );
    }
    final accent = PlannerHelpers.hexToColor(
      block!['color'] as String? ?? PlannerHelpers.categoryHex('personal'),
    );
    final duration = PlannerHelpers.blockDurationMinutes(date, block!);
    return FlowScaffold(
      title: 'Блок плана',
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: ListView(
        children: [
          FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _blockIcon(block!['category'] as String? ?? 'personal'),
                    color: accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  block!['title'] as String? ?? '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${DateTimeHelpers.formatTime(PlannerHelpers.blockStart(date, block!))} - ${DateTimeHelpers.formatTime(PlannerHelpers.blockEnd(date, block!))}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Продолжительность: $duration мин'),
                const SizedBox(height: 8),
                Text(
                  'Категория: ${PlannerHelpers.categoryLabel(block!['category'] as String? ?? 'personal')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FlowCard(
            child: Text(
              _blockDescription(block!['category'] as String? ?? 'personal'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _blockIcon(String category) {
    switch (PlannerHelpers.normalizePlanCategory(category)) {
      case 'study':
        return Icons.menu_book_rounded;
      case 'sport':
        return Icons.fitness_center_rounded;
      case 'rest':
        return Icons.self_improvement_rounded;
      case 'sleep':
        return Icons.nightlight_round;
      default:
        return Icons.favorite_outline_rounded;
    }
  }

  String _blockDescription(String category) {
    switch (PlannerHelpers.normalizePlanCategory(category)) {
      case 'study':
        return 'Это окно лучше использовать для глубокой учёбы без отвлечений. Подготовь материалы заранее и сосредоточься на одной задаче.';
      case 'sport':
        return 'Блок физической активности помогает восстановить энергию и удерживать концентрацию в течение дня.';
      case 'rest':
        return 'Небольшой перерыв снижает усталость и помогает вернуться к работе без перегруза.';
      case 'sleep':
        return 'Стабильный сон остаётся основой продуктивности, памяти и устойчивого ритма учёбы.';
      default:
        return 'Это гибкое личное окно. Его можно использовать для бытовых дел, дороги, обеда или свободного времени.';
    }
  }
}

class MorningBriefScreen extends StatelessWidget {
  const MorningBriefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>().currentPlan;
    return FlowScaffold(
      title: 'Утренний бриф',
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: ListView(
        children: [
          FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Настрой на день',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Сначала пройди по фиксированным событиям, затем закрой самую приоритетную задачу. FlowDay лучше работает, когда у дня есть один ясный фокус.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FlowCard(
            child: Text(
              plan == null
                  ? 'Пока нет ИИ-плана. Сгенерируй его на экране «Сегодня», чтобы получить персональную структуру дня.'
                  : 'В текущем плане ${plan.sortedBlocks.length} блоков, а доля учебных блоков составляет ${(plan.productivityPercent * 100).round()}%.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlannerTipsScreen extends StatelessWidget {
  const PlannerTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = <String>[
      'Добавляй пары и другие фиксированные события заранее, чтобы ИИ не ставил задачи поверх них.',
      'Высокий приоритет оставляй только для реально срочных задач с близким дедлайном.',
      'Сложные задачи лучше планировать на первое свободное окно, пока есть энергия.',
      'Не убирай перерывы из расписания: они помогают сохранить темп до вечера.',
      'Если день перегружен, сначала сократи второстепенные личные блоки, а не сон.',
    ];
    return FlowScaffold(
      title: 'Подсказки FlowDay',
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: ListView.separated(
        itemCount: tips.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => FlowCard(
          child: Text(
            tips[index],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.72),
      child: Center(
        child: FlowCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 18),
              Text(
                'FlowDay собирает расписание',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Добавляем сон, отдых, спорт и оптимальные учебные окна.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
