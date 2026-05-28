import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AdaptiveAvatar extends StatelessWidget {
  const AdaptiveAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 34,
  });

  final String photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'FD'
        : name.trim().split(' ').take(2).map((part) => part[0]).join();
    final provider = photoUrl.startsWith('http')
        ? CachedNetworkImageProvider(photoUrl)
        : photoUrl.isNotEmpty
        ? FileImage(File(photoUrl)) as ImageProvider
        : null;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: provider,
        child: provider == null
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.42,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }
}
