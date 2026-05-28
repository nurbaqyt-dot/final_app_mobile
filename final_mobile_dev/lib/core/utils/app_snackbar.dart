import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.surface,
        content: Text(message),
      ),
    );
}
