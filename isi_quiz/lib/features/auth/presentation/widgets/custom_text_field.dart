import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: readOnly,
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              onChanged: onChanged,
              maxLines: maxLines,
              enabled: enabled,
              readOnly: readOnly,
              decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: AppTheme.textSecondary,
                      size: 18,
                    )
                  : null,
              suffixIcon: suffixIcon,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
