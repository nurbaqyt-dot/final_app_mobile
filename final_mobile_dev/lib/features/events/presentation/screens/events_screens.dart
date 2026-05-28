import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/date_time_helpers.dart';
import '../../../../core/utils/planner_helpers.dart';
import '../../../../models/event_model.dart';
import '../../../../providers/event_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_scaffold.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    return FlowScaffold(
      title: 'События',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.eventCalendar),
          icon: const Icon(Icons.calendar_month_outlined),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.eventCategories),
          icon: const Icon(Icons.grid_view_rounded),
        ),
      ],
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addEvent),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Создать событие'),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: provider.eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? <EventModel>[];
          if (events.isEmpty) {
            return EmptyStateCard(
              title: 'Событий пока нет',
              subtitle:
                  'Добавь пары, смены, тренировки и личные встречи, чтобы FlowDay видел реальную структуру дня.',
              icon: Icons.event_busy_outlined,
              action: FilledButton(
                onPressed: () => context.push(AppRoutes.addEvent),
                child: const Text('Добавить событие'),
              ),
            );
          }
          final sections = _groupEvents(events);
          return ListView.separated(
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final section = sections[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeHelpers.formatLongDate(section.date),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${section.items.length} событий',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...section.items.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(event.id),
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
                          await provider.deleteEvent(event.id);
                          if (!context.mounted) {
                            return;
                          }
                          showAppSnackBar(context, 'Событие удалено.');
                        },
                        child: FlowCard(
                          onTap: () =>
                              context.push(AppRoutes.eventDetail, extra: event),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: PlannerHelpers.hexToColor(
                                    event.color,
                                  ).withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _eventIcon(event.category),
                                  color: PlannerHelpers.hexToColor(event.color),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(
                                    event.category,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }

  List<_EventSection> _groupEvents(List<EventModel> events) {
    final sorted = events.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final sections = <_EventSection>[];
    for (final event in sorted) {
      final day = DateTimeHelpers.dateOnly(event.startTime);
      if (sections.isEmpty ||
          !DateTimeHelpers.isSameDay(sections.last.date, day)) {
        sections.add(_EventSection(date: day, items: [event]));
      } else {
        sections.last.items.add(event);
      }
    }
    return sections;
  }
}

class AddEventScreen extends StatelessWidget {
  const AddEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EventFormScreen(title: 'Новое событие');
  }
}

class EditEventScreen extends StatelessWidget {
  const EditEventScreen({super.key, required this.event});

  final EventModel? event;

  @override
  Widget build(BuildContext context) {
    return _EventFormScreen(
      title: 'Редактировать событие',
      initialEvent: event,
      isEditing: true,
    );
  }
}

class _EventFormScreen extends StatefulWidget {
  const _EventFormScreen({
    required this.title,
    this.initialEvent,
    this.isEditing = false,
  });

  final String title;
  final EventModel? initialEvent;
  final bool isEditing;

  @override
  State<_EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<_EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;
  late String _category;
  late String _color;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _titleController.text = event?.title ?? '';
    _startTime =
        event?.startTime ?? DateTime.now().add(const Duration(hours: 1));
    _endTime = event?.endTime ?? _startTime.add(const Duration(hours: 1));
    _category = event?.category ?? AppConstants.eventCategories.first;
    _color = event?.color ?? PlannerHelpers.categoryHex(_category);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) {
      return;
    }
    setState(() {
      final combined = DateTimeHelpers.combineDateAndTimeOfDay(
        pickedDate,
        pickedTime,
      );
      if (isStart) {
        _startTime = combined;
        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = combined;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_endTime.isAfter(_startTime)) {
      showAppSnackBar(
        context,
        'Время окончания должно быть позже времени начала.',
        isError: true,
      );
      return;
    }
    try {
      final provider = context.read<EventProvider>();
      if (widget.isEditing && widget.initialEvent != null) {
        await provider.updateEvent(
          widget.initialEvent!.copyWith(
            title: _titleController.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            category: _category,
            color: _color,
          ),
        );
      } else {
        await provider.addEvent(
          title: _titleController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          category: _category,
          color: _color,
        );
      }
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Событие сохранено.');
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, _eventSaveError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
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
                  labelText: 'Название события',
                  hintText: 'Введите название события',
                  prefixIcon: Icon(Icons.event_note_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Введите понятное название события';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _PickerTile(
                title: 'Начало',
                value: DateTimeHelpers.formatDateTime(_startTime),
                icon: Icons.schedule_outlined,
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 12),
              _PickerTile(
                title: 'Окончание',
                value: DateTimeHelpers.formatDateTime(_endTime),
                icon: Icons.timelapse_rounded,
                onTap: () => _pickDateTime(isStart: false),
              ),
              const SizedBox(height: 20),
              Text(
                'Категория',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.eventCategories.map((category) {
                  return ChoiceChip(
                    selected: _category == category,
                    label: Text(category),
                    onSelected: (_) {
                      setState(() {
                        _category = category;
                        if (_color == PlannerHelpers.categoryHex(_category) ||
                            widget.initialEvent == null) {
                          _color = PlannerHelpers.categoryHex(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Цвет',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppConstants.presetColors.map((color) {
                  final colorHex = PlannerHelpers.colorToHex(color);
                  final selected = colorHex == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = colorHex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FlowButton(
                label: widget.isEditing
                    ? 'Сохранить изменения'
                    : 'Создать событие',
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

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final EventModel? event;

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return const FlowScaffold(
        title: 'Событие',
        padding: EdgeInsets.all(24),
        body: EmptyStateCard(
          title: 'Событие не найдено',
          subtitle: 'Не удалось открыть карточку выбранного события.',
          icon: Icons.error_outline_rounded,
        ),
      );
    }
    final accent = PlannerHelpers.hexToColor(event!.color);
    return FlowScaffold(
      title: 'Событие',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.editEvent, extra: event),
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
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(_eventIcon(event!.category), color: accent),
                ),
                const SizedBox(height: 16),
                Text(
                  event!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  title: 'Дата',
                  value: DateTimeHelpers.formatDate(event!.startTime),
                ),
                _DetailRow(
                  title: 'Время',
                  value:
                      '${DateTimeHelpers.formatTime(event!.startTime)} - ${DateTimeHelpers.formatTime(event!.endTime)}',
                ),
                _DetailRow(title: 'Категория', value: event!.category),
                _DetailRow(title: 'Цвет', value: event!.color),
              ],
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<EventProvider>().deleteEvent(event!.id);
              if (!context.mounted) {
                return;
              }
              showAppSnackBar(context, 'Событие удалено.');
              context.pop();
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Удалить событие'),
          ),
        ],
      ),
    );
  }
}

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateTimeHelpers.dateOnly(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDate = today;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    return FlowScaffold(
      title: 'Календарь событий',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 152),
      body: StreamBuilder<List<EventModel>>(
        stream: provider.eventsStream,
        builder: (context, snapshot) {
          final events = snapshot.data ?? <EventModel>[];
          final selectedEvents = provider.filterForDate(events, _selectedDate);
          final todayEvents = provider.filterForDate(events, DateTime.now());
          return ListView(
            children: [
              FlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month - 1,
                            );
                          }),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'LLLL yyyy',
                              'ru_RU',
                            ).format(_visibleMonth),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _visibleMonth = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month + 1,
                            );
                          }),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _MonthGrid(
                      month: _visibleMonth,
                      selectedDate: _selectedDate,
                      events: events,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                          _visibleMonth = DateTime(date.year, date.month);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ScheduleSection(
                title: 'Сегодня',
                emptyText: 'Сегодня событий нет',
                events: todayEvents,
              ),
              const SizedBox(height: 16),
              FlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateTimeHelpers.formatLongDate(_selectedDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (selectedEvents.isEmpty)
                      Text(
                        'На эту дату событий нет',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      ...selectedEvents.map(
                        (event) => _CalendarEventRow(
                          event: event,
                          onTap: () =>
                              context.push(AppRoutes.eventDetail, extra: event),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.events,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime selectedDate;
  final List<EventModel> events;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday - 1;
    final cells = leadingEmptyCells + daysInMonth;
    final rowCount = (cells / 7).ceil();

    return Column(
      children: [
        Row(
          children: weekdays
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rowCount * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingEmptyCells + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(month.year, month.month, dayNumber);
            final selected = DateTimeHelpers.isSameDay(date, selectedDate);
            final dayEvents =
                events
                    .where(
                      (event) =>
                          DateTimeHelpers.isSameDay(event.startTime, date),
                    )
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onDateSelected(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.28)
                      : AppColors.surface.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.tertiary : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNumber.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dayEvents.take(3).map((event) {
                        return Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: PlannerHelpers.hexToColor(event.color),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.title,
    required this.emptyText,
    required this.events,
  });

  final String title;
  final String emptyText;
  final List<EventModel> events;

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
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Text(
              emptyText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            ...events.map((event) => _CalendarEventRow(event: event)),
        ],
      ),
    );
  }
}

class _CalendarEventRow extends StatelessWidget {
  const _CalendarEventRow({required this.event, this.onTap});

  final EventModel event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = PlannerHelpers.hexToColor(event.color);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${DateTimeHelpers.formatTime(event.startTime)} - ${DateTimeHelpers.formatTime(event.endTime)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCategoriesScreen extends StatelessWidget {
  const EventCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const descriptions = <String, String>{
      'Учёба': 'Пары, лабораторные, подготовка, консультации.',
      'Спорт': 'Тренировки, прогулки, зал и активное восстановление.',
      'Работа': 'Смена, стажировка, подработка или проектная работа.',
      'Отдых': 'Обед, передышка, восстановление и паузы.',
      'Личное': 'Домашние дела, встречи, дорога и личное время.',
      'Другое': 'Всё, что не попадает в основные категории.',
    };
    return FlowScaffold(
      title: 'Категории событий',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: GridView.builder(
        itemCount: AppConstants.eventCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 164,
        ),
        itemBuilder: (context, index) {
          final category = AppConstants.eventCategories[index];
          final color = PlannerHelpers.eventCategoryColor(category);
          return FlowCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_eventIcon(category), color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descriptions[category] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

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

class _EventSection {
  _EventSection({required this.date, required this.items});

  final DateTime date;
  final List<EventModel> items;
}

IconData _eventIcon(String category) {
  switch (PlannerHelpers.normalizeEventCategory(category)) {
    case 'Учёба':
      return Icons.school_outlined;
    case 'Спорт':
      return Icons.fitness_center_outlined;
    case 'Работа':
      return Icons.work_outline_rounded;
    case 'Отдых':
      return Icons.spa_outlined;
    case 'Другое':
      return Icons.extension_outlined;
    default:
      return Icons.favorite_border_rounded;
  }
}

String _eventSaveError(Object error) {
  if (error is ArgumentError || error is StateError) {
    return error.toString().replaceFirst(
      RegExp(r'^(Invalid argument\(s\)|Bad state): '),
      '',
    );
  }
  return 'Не удалось сохранить событие.';
}
