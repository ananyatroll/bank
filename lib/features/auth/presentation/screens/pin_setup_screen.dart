import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../config/constants.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_pinController.text != _confirmController.text) {
        setState(() => _errorMessage = 'PINs do not match');
        return;
      }

      // TODO: Save PIN using pinVaultProvider
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to set up PIN: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.s32),
                Icon(Icons.lock_outline, size: 80, color: AppColors.ethiopianGreen),
                const SizedBox(height: AppSpacing.s24),
                Text(
                  'Create Your PIN',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Enter a ${AppConstants.pinLength}-digit PIN to secure your account',
                  style: AppTextStyles.bodyMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s32),
                CustomTextField(
                  label: 'Enter PIN',
                  hint: 'Enter ${AppConstants.pinLength}-digit PIN',
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: AppConstants.pinLength,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'PIN is required';
                    if (value.length != AppConstants.pinLength) return 'PIN must be ${AppConstants.pinLength} digits';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                CustomTextField(
                  label: 'Confirm PIN',
                  hint: 'Re-enter your PIN',
                  controller: _confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: AppConstants.pinLength,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'PIN confirmation is required';
                    if (value.length != AppConstants.pinLength) return 'PIN must be ${AppConstants.pinLength} digits';
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                CustomButton(
                  text: 'Continue',
                  onPressed: _isLoading ? null : _handleSetup,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
