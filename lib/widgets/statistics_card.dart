// widgets/statistics_card.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/notification.dart';

class StatisticsCard extends StatelessWidget {
  final NotificationStatistics statistics;
  final int unreadCount;

  const StatisticsCard({
    Key? key,
    required this.statistics,
    required this.unreadCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', statistics.totalCount, Iconsax.notification),
          _buildStatItem('Lues', statistics.readCount, Iconsax.eye),
          _buildStatItem('Non lues', unreadCount, Iconsax.eye_slash),
          _buildStatItem(
            'Taux',
            '${statistics.readPercentage.toStringAsFixed(1)}%',
            Iconsax.chart_1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
