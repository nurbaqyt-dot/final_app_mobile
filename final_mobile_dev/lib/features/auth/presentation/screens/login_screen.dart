import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/flow_button.dart';
import '../../../../widgets/flow_card.dart';
import '../../../../widgets/flow_logo.dart';
import '../../../../widgets/flow_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await context.read<AuthProvider>().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.today);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Не удалось выполнить вход.', isError: true);
    }
  }

  Future<void> _google() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.today);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        'Не удалось выполнить вход через Google.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return FlowScaffold(
      showAppBar: false,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: FlowLogo(size: 96)),
              const SizedBox(height: 28),
              Text(
                'Вход в FlowDay',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Открой свой план дня, задачи и расписание в одном месте.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              if (auth.isDemoMode) ...[
                const SizedBox(height: 18),
                const FlowCard(
                  child: Text(
                    'Активен демонстрационный режим. Если Firebase или API не подключены, FlowDay использует локальные данные.',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Почта',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
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
              const SizedBox(height: 22),
              FlowButton(
                label: 'Войти',
                isLoading: auth.isBusy,
                onPressed: _login,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: auth.isBusy ? null : _google,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Войти через Google'),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text('Создать аккаунт'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
