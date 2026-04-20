import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PasswordValidationWidget extends StatelessWidget {
  final String password;
  final bool showValidation;

  const PasswordValidationWidget({
    super.key,
    required this.password,
    this.showValidation = false,
  });

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get hasNumbers => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialCharacters => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    if (!showValidation) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Le mot de passe doit contenir :',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        _buildValidationItem('Au moins 8 caractères', hasMinLength),
        _buildValidationItem('Au moins une lettre majuscule', hasUppercase),
        _buildValidationItem('Au moins une lettre minuscule', hasLowercase),
        _buildValidationItem('Au moins un chiffre', hasNumbers),
        _buildValidationItem('Au moins un caractère spécial (!@#\$%^&*)', hasSpecialCharacters),
      ],
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? AppTheme.successColor : AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppTheme.successColor : AppTheme.textSecondary,
              decoration: isValid ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
