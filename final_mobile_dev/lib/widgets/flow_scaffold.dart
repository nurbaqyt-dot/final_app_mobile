import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.padding,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showAppBar = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? body
        : Padding(padding: padding!, child: body);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: true,
      appBar: showAppBar
          ? AppBar(title: title == null ? null : Text(title!), actions: actions)
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.darkPurple],
          ),
        ),
        child: Stack(
          children: [
            ColoredBox(
              color: AppColors.background.withValues(alpha: 0.86),
              child: const SizedBox.expand(),
            ),
            SafeArea(child: content),
          ],
        ),
      ),
    );
  }
}
