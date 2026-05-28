import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../router/app_router.dart';
import '../../../../widgets/flow_logo.dart';
import '../../../../widgets/flow_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), _goNext);
  }

  void _goNext() {
    if (!mounted) {
      return;
    }
    final auth = context.read<AuthProvider>();
    if (!auth.onboardingSeen) {
      context.go(AppRoutes.onboarding1);
      return;
    }
    if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }
    context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    return const FlowScaffold(showAppBar: false, body: _SplashBody());
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FlowLogo(size: 110).animate().fadeIn(duration: 500.ms).scale(),
          const SizedBox(height: 36),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ],
      ),
    );
  }
}
