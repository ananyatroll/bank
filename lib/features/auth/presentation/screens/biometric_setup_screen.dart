import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../shared/widgets/custom_button.dart';

class BiometricSetupScreen extends ConsumerWidget {
  const BiometricSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Authentication')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.fingerprint, size: 100, color: AppColors.ethiopianGreen),
              const SizedBox(height: 24),
              Text(
                'Enable Biometric Auth',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Use your fingerprint or face ID for quick and secure access to your account',
                style: AppTextStyles.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeature(
                icon: Icons.speed,
                title: 'Quick Access',
                description: 'Unlock your account in seconds',
              ),
              const SizedBox(height: 16),
              _buildFeature(
                icon: Icons.security,
                title: 'Secure',
                description: 'Your biometric data never leaves your device',
              ),
              const SizedBox(height: 16),
              _buildFeature(
                icon: Icons.lock_outline,
                title: 'PIN Backup',
                description: 'Your PIN is always available as a backup option',
              ),
              const Spacer(),
              CustomButton(
                text: 'Enable Biometric',
                onPressed: () {
                  // TODO: Enable biometric auth
                  Navigator.of(context).pop(true);
                },
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Skip for Now',
                onPressed: () => Navigator.of(context).pop(false),
                type: ButtonType.text,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature({required IconData icon, required String title, required String description}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.ethiopianGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.ethiopianGreen),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600)),
              Text(description, style: AppTextStyles.bodyMd),
            ],
          ),
        ),
      ],
    );
  }
}
