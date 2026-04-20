import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EnhancedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const EnhancedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.borderRadius,
    this.borderSide,
  });

  factory EnhancedButton.primary({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return EnhancedButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppTheme.primaryColor,
      textColor: Colors.white,
      height: 50,
      borderRadius: BorderRadius.circular(12),
    );
  }

  factory EnhancedButton.secondary({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return EnhancedButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: Colors.transparent,
      textColor: AppTheme.primaryColor,
      height: 50,
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: backgroundColor == Colors.transparent ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            side: borderSide ?? BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: textColor ?? AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: textColor ?? AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
