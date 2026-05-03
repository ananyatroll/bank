import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum ButtonType { primary, secondary, outline, text, icon }

class CustomButton extends StatelessWidget {
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final EdgeInsets? padding;
  final Widget? child;

  const CustomButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
    this.padding,
    this.child,
  }) : assert(text != null || child != null || icon != null, 'Must provide text, child, or icon');

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);
    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildButton(BuildContext context) {
    final Widget content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.primary ? AppColors.white : AppColors.ethiopianGreen,
              ),
            ),
          )
        : child ?? Text(text!, style: AppTextStyles.button);

    switch (type) {
      case ButtonType.primary:
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.getShadow(4),
          ),
          height: height ?? 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: icon != null
                ? Row(mainAxisSize: MainAxisSize.min, children: [icon!, const SizedBox(width: 8), content])
                : content,
          ),
        );
      case ButtonType.secondary:
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.getShadow(2),
          ),
          height: height ?? 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: AppTextStyles.button.copyWith(color: AppColors.navyBlue),
            ),
            child: icon != null
                ? Row(mainAxisSize: MainAxisSize.min, children: [icon!, const SizedBox(width: 8), content])
                : DefaultTextStyle(style: AppTextStyles.button.copyWith(color: AppColors.navyBlue), child: content),
          ),
        );
      case ButtonType.outline:
        return SizedBox(
          height: height ?? 48,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.ethiopianGreen, width: 2),
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: icon != null
                ? Row(mainAxisSize: MainAxisSize.min, children: [icon!, const SizedBox(width: 8), content])
                : content,
          ),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
      case ButtonType.icon:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.ethiopianGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: isLoading ? null : onPressed,
            icon: icon ?? const Icon(Icons.add),
            color: AppColors.ethiopianGreen,
          ),
        );
    }
  }
}
