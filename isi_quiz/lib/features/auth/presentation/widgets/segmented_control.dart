import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class SegmentedControl extends StatelessWidget {
  final List<String> options;
  final String selectedOption;
  final Function(String) onOptionChanged;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = option == selectedOption;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onOptionChanged(option),
              child: Container(
                margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius - 4),
                ),
                child: Center(
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
