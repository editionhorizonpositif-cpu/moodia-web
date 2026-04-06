/*import 'package:flutter/material.dart';

class ChallengeStatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const ChallengeStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(status);

    if (isCompact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: statusData.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusData.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusData.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            statusData.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusData.color,
            ),
          ),
        ],
      ),
    );
  }
}

StatusData _getStatusData(String status) {
  switch (status.toUpperCase()) {
    case 'ACTIVE':
    case 'JOINED':
    case 'IN_PROGRESS':
      return const StatusData(label: 'En cours', color: Color(0xFF2196F3));
    case 'COMPLETED':
      return const StatusData(label: 'Terminé', color: Color(0xFF4CAF50));
    case 'DRAFT':
      return const StatusData(label: 'Brouillon', color: Color(0xFF9E9E9E));
    case 'PAUSED':
      return const StatusData(label: 'En pause', color: Color(0xFFFFC107));
    case 'FAILED':
    case 'ABANDONED':
    case 'CANCELLED':
      return const StatusData(label: 'Abandonné', color: Color(0xFFF44336));
    case 'ARCHIVED':
      return const StatusData(label: 'Archivé', color: Color(0xFF607D8B));
    case 'INVITED':
      return const StatusData(label: 'Invité', color: Color(0xFF9C27B0));
    default:
      return const StatusData(label: 'Inconnu', color: Color(0xFF9E9E9E));
  }
}

class StatusData {
  final String label;
  final Color color;

  const StatusData({required this.label, required this.color});
}*/
