import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_helpers.dart';
import '../../../../core/utils/planner_helpers.dart';
import '../../../../models/day_plan_model.dart';
import '../../../../models/event_model.dart';
import '../../../../models/task_model.dart';
import '../../../../providers/event_provider.dart';
import '../../../../providers/plan_provider.dart';
import '../../../../providers/task_provider.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_scaffold.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final eventProvider = context.watch<EventProvider>();
    final planProvider = context.watch<PlanProvider>();

    return FlowScaffold(
      title: 'Статистика',
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProductivityTrendsScreen(),
            ),
          ),
          icon: const Icon(Icons.show_chart_rounded),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WeeklyReviewScreen()),
          ),
          icon: const Icon(Icons.view_week_outlined),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskProvider.tasksStream,
        builder: (context, taskSnapshot) {
          final tasks = taskSnapshot.data ?? <TaskModel>[];
          return StreamBuilder<List<EventModel>>(
            stream: eventProvider.eventsStream,
            builder: (context, eventSnapshot) {
              final events = eventSnapshot.data ?? <EventModel>[];
              final plan = planProvider.currentPlan;
              final completed = tasks.where((task) => task.isDone).length;
              final completionPercent = tasks.isEmpty
                  ? 0.0
                  : completed / tasks.length;
              final pending = tasks.where((task) => !task.isDone).length;
              return ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Выполнение',
                          value: '${(completionPercent * 100).round()}%',
                          subtitle: '$completed из ${tasks.length} задач',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Фокус плана',
                          value: plan == null
                              ? '0%'
                              : '${(plan.productivityPercent * 100).round()}%',
                          subtitle: 'доля учебных блоков',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'События',
                          value: events.length.toString(),
                          subtitle: 'в календаре',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Активные',
                          value: pending.toString(),
                          subtitle: 'задач в работе',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Прогресс по задачам',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: _CompletionPieChart(
                            completed: completed,
                            pending: pending,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Завершения за 7 дней',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: _TasksBarChart(tasks: tasks),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FlowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Структура текущего плана',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (plan == null)
                          const EmptyStateCard(
                            title: 'План дня ещё не построен',
                            subtitle:
                                'Когда появится ИИ-план, здесь будет видно распределение учебных, личных и восстановительных блоков.',
                            icon: Icons.auto_awesome_outlined,
                          )
                        else
                          ..._buildPlanCategoryRows(context, plan),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildPlanCategoryRows(BuildContext context, DayPlanModel plan) {
    final minutesByCategory = <String, int>{};
    for (final block in plan.sortedBlocks) {
      final category = PlannerHelpers.normalizePlanCategory(
        block['category'] as String? ?? '',
      );
      minutesByCategory[category] =
          (minutesByCategory[category] ?? 0) +
          PlannerHelpers.blockDurationMinutes(plan.date, block);
    }
    final total = minutesByCategory.values.fold<int>(
      0,
      (sum, item) => sum + item,
    );
    return minutesByCategory.entries.map((entry) {
      final percent = total == 0 ? 0.0 : entry.value / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(PlannerHelpers.categoryLabel(entry.key))),
                Text(
                  '${(percent * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              valueColor: AlwaysStoppedAnimation<Color>(
                PlannerHelpers.planCategoryColor(entry.key),
              ),
              backgroundColor: AppColors.surface,
            ),
          ],
        ),
      );
    }).toList();
  }
}

class ProductivityTrendsScreen extends StatelessWidget {
  const ProductivityTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: 'Тренды продуктивности',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskProvider.tasksStream,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? <TaskModel>[];
          final days = DateTimeHelpers.last7Days();
          final values = days.map((day) {
            return tasks
                .where(
                  (task) =>
                      DateTimeHelpers.isSameDay(task.deadline, day) &&
                      task.isDone,
                )
                .length;
          }).toList();
          final maxValue = values.fold<int>(
            1,
            (max, value) => value > max ? value : max,
          );
          return ListView(
            children: [
              FlowCard(
                child: SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: (maxValue + 1).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.border, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateTimeHelpers.formatMonthDay(
                                  days[value.toInt()],
                                ),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.secondary,
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.16),
                          ),
                          dotData: const FlDotData(show: true),
                          spots: List<FlSpot>.generate(
                            values.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              values[index].toDouble(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final eventProvider = context.watch<EventProvider>();
    final plan = context.watch<PlanProvider>().currentPlan;

    return FlowScaffold(
      title: 'Итоги недели',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskProvider.tasksStream,
        builder: (context, taskSnapshot) {
          final tasks = taskSnapshot.data ?? <TaskModel>[];
          return StreamBuilder<List<EventModel>>(
            stream: eventProvider.eventsStream,
            builder: (context, eventSnapshot) {
              final events = eventSnapshot.data ?? <EventModel>[];
              final completed = tasks.where((task) => task.isDone).length;
              final studyEvents = events
                  .where((event) => event.category == 'Учёба')
                  .length;
              final completionPercent = tasks.isEmpty
                  ? 0
                  : ((completed / tasks.length) * 100).round();
              return ListView(
                children: [
                  _StatCard(
                    title: 'Выполнение задач',
                    value: '$completionPercent%',
                    subtitle: '$completed задач закрыто за текущий период',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Учебные события',
                    value: '$studyEvents',
                    subtitle: 'запланировано в календаре',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Фокус ИИ-плана',
                    value: plan == null
                        ? 'Нет плана'
                        : '${(plan.productivityPercent * 100).round()}%',
                    subtitle: 'доля учебных блоков в последнем плане',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TasksBarChart extends StatelessWidget {
  const _TasksBarChart({required this.tasks});

  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final days = DateTimeHelpers.last7Days();
    final doneByDay = days.map((day) {
      return tasks
          .where(
            (task) =>
                DateTimeHelpers.isSameDay(task.deadline, day) && task.isDone,
          )
          .length;
    }).toList();

    return BarChart(
      BarChartData(
        maxY:
            (doneByDay.fold<int>(1, (max, value) => value > max ? value : max) +
                    1)
                .toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                DateTimeHelpers.formatMonthDay(days[value.toInt()]),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List<BarChartGroupData>.generate(
          doneByDay.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: doneByDay[index].toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.darkPurple],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionPieChart extends StatelessWidget {
  const _CompletionPieChart({required this.completed, required this.pending});

  final int completed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    if (completed == 0 && pending == 0) {
      return const EmptyStateCard(
        title: 'Статистика ещё не накопилась',
        subtitle: 'Добавь задачи, чтобы увидеть диаграмму выполнения.',
        icon: Icons.pie_chart_outline_rounded,
      );
    }
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 48,
        sections: [
          PieChartSectionData(
            color: AppColors.success,
            value: completed.toDouble(),
            title: 'Готово\n$completed',
            radius: 76,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          PieChartSectionData(
            color: AppColors.warning,
            value: pending.toDouble(),
            title: 'В работе\n$pending',
            radius: 76,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
