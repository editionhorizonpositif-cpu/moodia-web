/*import 'package:flutter/material.dart';

class ChallengeProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final bool showPercentage;
  final Color? color;
  final String? label;
  final String? subtitle;

  const ChallengeProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.showPercentage = false,
    this.color,
    this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 100.0);
    final progressColor = color ?? _getProgressColor(clampedProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              if (showPercentage)
                Text(
                  '${clampedProgress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
            ],
          ),
        if (label != null || showPercentage) const SizedBox(height: 4),
        Stack(
          children: [
            // Fond
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Progression
            FractionallySizedBox(
              widthFactor: clampedProgress / 100,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [progressColor.withOpacity(0.7), progressColor],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 25) {
      return Colors.blue;
    } else if (progress < 50) {
      return Colors.lightBlue;
    } else if (progress < 75) {
      return Colors.amber;
    } else if (progress < 90) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}*/
