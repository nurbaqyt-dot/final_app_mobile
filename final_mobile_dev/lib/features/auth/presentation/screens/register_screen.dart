import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_logo.dart';
import '../../../../widgets/flow_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await context.read<AuthProvider>().register(
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Аккаунт создан.');
      context.go(AppRoutes.today);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Не удалось создать аккаунт.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return FlowScaffold(
      title: 'Регистрация',
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: FlowLogo(size: 88)),
              const SizedBox(height: 24),
              Text(
                'Создай свой FlowDay',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Подключи аккаунт JIHC и начни строить умные планы на каждый день.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя и фамилия',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'ID студента',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите ID студента';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Почта',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Введите корректную почту';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FlowButton(
                label: 'Создать аккаунт',
                isLoading: auth.isBusy,
                onPressed: _register,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('У меня уже есть аккаунт'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
