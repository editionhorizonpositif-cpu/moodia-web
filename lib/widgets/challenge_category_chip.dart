/*import 'package:flutter/material.dart';
import '../models/challenge_category.dart';

class ChallengeCategoryChip extends StatelessWidget {
  final ChallengeCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const ChallengeCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.colorCode != null
        ? Color(int.parse('0xFF${category.colorCode!.substring(1)}'))
        : const Color(0xFF7DBBC3);

    return FilterChip(
      label: Text(category.name),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      avatar: category.icon != null
          ? Icon(
              Icons.category,
              size: 16,
              color: isSelected ? color : Colors.grey[500],
            )
          : null,
      side: BorderSide(color: isSelected ? color : Colors.grey[300]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}*/
