/*import 'package:flutter/material.dart';

class ChallengeDifficultyIndicator extends StatelessWidget {
  final String difficulty;
  final double size;
  final bool showLabel;

  const ChallengeDifficultyIndicator({
    super.key,
    required this.difficulty,
    this.size = 24,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyData = _getDifficultyData(difficulty);

    return Tooltip(
      message: difficultyData.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: difficultyData.color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: difficultyData.color, width: 2),
        ),
        child: Center(
          child: showLabel
              ? Text(
                  difficultyData.shortLabel,
                  style: TextStyle(
                    color: difficultyData.color,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(
                  Icons.fitness_center,
                  size: size * 0.6,
                  color: difficultyData.color,
                ),
        ),
      ),
    );
  }

  DifficultyData _getDifficultyData(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        return const DifficultyData(
          label: 'Débutant',
          shortLabel: 'D',
          color: Color(0xFF4CAF50),
        );
      case 'EASY':
        return const DifficultyData(
          label: 'Facile',
          shortLabel: 'F',
          color: Color(0xFF8BC34A),
        );
      case 'MEDIUM':
        return const DifficultyData(
          label: 'Intermédiaire',
          shortLabel: 'I',
          color: Color(0xFFFFC107),
        );
      case 'HARD':
        return const DifficultyData(
          label: 'Difficile',
          shortLabel: 'Df',
          color: Color(0xFFFF9800),
        );
      case 'EXPERT':
        return const DifficultyData(
          label: 'Expert',
          shortLabel: 'E',
          color: Color(0xFFF44336),
        );
      case 'MASTER':
        return const DifficultyData(
          label: 'Maître',
          shortLabel: 'M',
          color: Color(0xFF9C27B0),
        );
      default:
        return const DifficultyData(
          label: 'Intermédiaire',
          shortLabel: 'I',
          color: Color(0xFFFFC107),
        );
    }
  }
}

class DifficultyData {
  final String label;
  final String shortLabel;
  final Color color;

  const DifficultyData({
    required this.label,
    required this.shortLabel,
    required this.color,
  });
}*/
