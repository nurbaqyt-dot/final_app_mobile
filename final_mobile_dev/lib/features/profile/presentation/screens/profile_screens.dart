import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../models/task_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/task_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/adaptive_avatar.dart';
import '../../../../widgets/empty_state_card.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_logo.dart';
import '../../../../widgets/flow_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const FlowScaffold(
        title: 'Профиль',
        padding: EdgeInsets.all(24),
        body: EmptyStateCard(
          title: 'Профиль недоступен',
          subtitle: 'Выполни вход, чтобы открыть личный кабинет FlowDay.',
          icon: Icons.person_off_outlined,
        ),
      );
    }
    return FlowScaffold(
      title: 'Профиль',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: context.watch<TaskProvider>().tasksStream,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? <TaskModel>[];
          final completed = tasks.where((task) => task.isDone).length;
          final active = tasks.where((task) => !task.isDone).length;
          final completionPercent = tasks.isEmpty
              ? 0
              : ((completed / tasks.length) * 100).round();
          return ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    const FlowLogo(size: 74, showText: false),
                    const SizedBox(height: 18),
                    AdaptiveAvatar(
                      photoUrl: user.photoUrl,
                      name: auth.displayName,
                      radius: 46,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.editProfile),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Изменить'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.photoUpload),
                            icon: const Icon(Icons.photo_camera_back_outlined),
                            label: const Text('Фото'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _StudentIdCard(
                name: auth.displayName,
                studentId: user.studentId,
                email: user.email,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      title: 'Выполнено',
                      value: completed.toString(),
                      subtitle: 'закрытых задач',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStat(
                      title: 'Активные',
                      value: active.toString(),
                      subtitle: 'ещё в работе',
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileStat(
                      title: 'Прогресс',
                      value: '$completionPercent%',
                      subtitle: 'выполнение задач',
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FlowCard(
                child: Row(
                  children: [
                    const FlowLogo(size: 58, showText: false),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'О FlowDay',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'FlowDay помогает студентам JIHC держать под контролем пары, дедлайны, спорт и свободное время в одном тёмном, чистом интерфейсе.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FlowCard(
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.query_stats_rounded,
                      title: 'Статистика',
                      onTap: () => context.push(AppRoutes.statistics),
                    ),
                    _MenuTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Достижения',
                      onTap: () => context.push(AppRoutes.achievements),
                    ),
                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Уведомления',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Настройки',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'О приложении',
                      onTap: () => context.push(AppRoutes.about),
                    ),
                    _MenuTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Поддержка',
                      onTap: () => context.push(AppRoutes.support),
                      showDivider: false,
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _studentIdController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _studentIdController = TextEditingController(text: user?.studentId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await context.read<ProfileProvider>().updateProfile(
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Профиль обновлён.');
      context.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Не удалось сохранить профиль.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return FlowScaffold(
      title: 'Редактировать профиль',
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя и фамилия',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Введите имя и фамилию'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'ID студента',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Введите ID студента'
                    : null,
              ),
              const SizedBox(height: 24),
              FlowButton(
                label: 'Сохранить',
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

class PhotoUploadScreen extends StatelessWidget {
  const PhotoUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return FlowScaffold(
      title: 'Фото профиля',
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlowCard(
            child: Text(
              'Выбери источник фотографии. FlowDay загрузит изображение в подключённое хранилище и сразу обновит профиль.',
            ),
          ),
          const SizedBox(height: 16),
          FlowCard(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Сделать фото',
                  onTap: () => _upload(context, ImageSource.camera),
                ),
                _MenuTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Выбрать из галереи',
                  onTap: () => _upload(context, ImageSource.gallery),
                  showDivider: false,
                ),
              ],
            ),
          ),
          if (provider.isBusy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _upload(BuildContext context, ImageSource source) async {
    try {
      await context.read<ProfileProvider>().uploadPhoto(source);
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, 'Фото обновлено.');
      context.pop();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(context, 'Не удалось загрузить фото.', isError: true);
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _summaryEnabled = true;
  bool _autoPlanHints = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return FlowScaffold(
      title: 'Настройки',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: ListView(
        children: [
          FlowCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: null,
                  title: const Text('Тёмная тема'),
                  subtitle: const Text('FlowDay работает в единой тёмной теме'),
                ),
                SwitchListTile(
                  value: _pushEnabled,
                  onChanged: (value) => setState(() => _pushEnabled = value),
                  title: const Text('Push-уведомления'),
                  subtitle: const Text('Напоминания о задачах и событиях'),
                ),
                SwitchListTile(
                  value: _summaryEnabled,
                  onChanged: (value) => setState(() => _summaryEnabled = value),
                  title: const Text('Ежедневная сводка'),
                  subtitle: const Text('Утренний обзор плана на день'),
                ),
                SwitchListTile(
                  value: _autoPlanHints,
                  onChanged: (value) => setState(() => _autoPlanHints = value),
                  title: const Text('Подсказки по плану'),
                  subtitle: const Text('Советы по балансу учёбы и отдыха'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FlowButton(
            label: 'Выйти из аккаунта',
            isLoading: auth.isBusy,
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _morning = true;
  bool _deadline = true;
  bool _rest = false;

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      title: 'Уведомления',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: ListView(
        children: [
          FlowCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _morning,
                  onChanged: (value) => setState(() => _morning = value),
                  title: const Text('Утренний план'),
                  subtitle: const Text('Напоминать открыть план утром'),
                ),
                SwitchListTile(
                  value: _deadline,
                  onChanged: (value) => setState(() => _deadline = value),
                  title: const Text('Дедлайны'),
                  subtitle: const Text('Напоминать о ближайших сроках'),
                ),
                SwitchListTile(
                  value: _rest,
                  onChanged: (value) => setState(() => _rest = value),
                  title: const Text('Перерывы'),
                  subtitle: const Text('Напоминать делать паузы между блоками'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      title: 'О приложении',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: ListView(
        children: [
          const FlowCard(child: Center(child: FlowLogo(size: 92))),
          const SizedBox(height: 16),
          FlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _IdentityRow(title: 'Приложение', value: AppConstants.appName),
                _IdentityRow(
                  title: 'Разработчик',
                  value: AppConstants.developerName,
                ),
                _IdentityRow(title: 'Колледж', value: AppConstants.college),
                _IdentityRow(
                  title: 'Основной цвет',
                  value: AppConstants.primaryHex,
                ),
                _IdentityRow(
                  title: 'Модель ИИ',
                  value: AppConstants.anthropicModel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return FlowScaffold(
      title: 'Достижения',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: StreamBuilder<List<TaskModel>>(
        stream: provider.tasksStream,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? <TaskModel>[];
          final completed = tasks.where((task) => task.isDone).length;
          final achievements =
              <({String title, String subtitle, bool unlocked})>[
                (
                  title: 'Первый ритм',
                  subtitle: 'Закрыть первую задачу.',
                  unlocked: completed >= 1,
                ),
                (
                  title: 'Пять в потоке',
                  subtitle: 'Завершить 5 задач.',
                  unlocked: completed >= 5,
                ),
                (
                  title: 'Стабильный темп',
                  subtitle: 'Завершить 10 задач.',
                  unlocked: completed >= 10,
                ),
              ];
          return ListView.separated(
            itemCount: achievements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = achievements[index];
              return FlowCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.unlocked
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        item.unlocked
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline_rounded,
                        color: item.unlocked
                            ? AppColors.tertiary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faq = <({String q, String a})>[
      (
        q: 'Как собрать план на день?',
        a: 'Добавь события и задачи, затем на экране «Сегодня» нажми кнопку генерации. FlowDay подберёт учебные блоки, отдых и спорт.',
      ),
      (
        q: 'Почему план выглядит не так, как я ожидал?',
        a: 'Точность зависит от введённых данных. Чем подробнее указаны события и дедлайны, тем лучше результат.',
      ),
      (
        q: 'Можно ли пользоваться приложением без сети?',
        a: 'Да. Если внешние сервисы недоступны, FlowDay использует локальные сценарии и базовый генератор плана.',
      ),
    ];
    return FlowScaffold(
      title: 'Поддержка',
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: ListView.separated(
        itemCount: faq.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq[index].q,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                faq[index].a,
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

class EmptyStateDemoScreen extends StatelessWidget {
  const EmptyStateDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlowScaffold(
      title: 'Пустые состояния',
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
      body: _EmptyDemoBody(),
    );
  }
}

class _EmptyDemoBody extends StatelessWidget {
  const _EmptyDemoBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        EmptyStateCard(
          title: 'Пока нет плана',
          subtitle:
              'Этот экран показывает, как FlowDay сообщает о следующих шагах до первого действия пользователя.',
          icon: Icons.auto_awesome_outlined,
        ),
        SizedBox(height: 16),
        EmptyStateCard(
          title: 'Нет событий',
          subtitle:
              'Пустой экран тоже должен направлять пользователя и объяснять ценность следующего действия.',
          icon: Icons.event_busy_outlined,
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.tertiary, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.tertiary),
          ),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.title, required this.value});

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

class _StudentIdCard extends StatelessWidget {
  const _StudentIdCard({
    required this.name,
    required this.studentId,
    required this.email,
  });

  final String name;
  final String studentId;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.darkPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FlowCard(
        padding: const EdgeInsets.all(0),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.darkPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FlowLogo(size: 56, showText: false),
                  const Spacer(),
                  Text(
                    'СТУДЕНТ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CardField(title: 'ID студента', value: studentId),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardField(
                      title: 'Колледж',
                      value: AppConstants.college,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
