import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'custom_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool showIcon;

  const AppErrorWidget({
    super.key,
    this.message = 'An error occurred',
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                icon,
                size: 64,
                color: AppColors.error.withOpacity(0.6),
              ),
            if (showIcon) const SizedBox(height: AppSpacing.s16),
            Text(
              message,
              style: AppTextStyles.h3.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                details!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s24),
              CustomButton(
                text: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: AppColors.mediumGray.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.s16),
            Text(
              message,
              style: AppTextStyles.h3.copyWith(color: AppColors.mediumGray),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.s24),
              CustomButton(text: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
