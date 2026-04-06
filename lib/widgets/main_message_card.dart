import 'package:flutter/material.dart';
import '../models/main_message.dart';

class MainMessageCard extends StatelessWidget {
  final MainMessage message;
  final VoidCallback? onTap;
  final bool showActions;
  final Function(bool)? onToggleStatus;
  final Function()? onDelete;

  const MainMessageCard({
    Key? key,
    required this.message,
    this.onTap,
    this.showActions = false,
    this.onToggleStatus,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec type et priorité
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      message.type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getColorForType(message.type),
                  ),
                  if (message.priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(message.priority!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Priorité: ${message.priority}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Titre
              Text(
                message.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Message
              Text(
                message.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              // Description (si présente)
              if (message.description != null &&
                  message.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    message.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              // URL (si présente)
              if (message.url != null && message.url!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Lien: ${message.url!}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              // Audience et dates
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (message.targetAudience != null)
                    Chip(
                      label: Text(
                        message.targetAudience!,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.grey[200],
                    ),
                  if (message.startDate != null)
                    Chip(
                      label: Text(
                        'Début: ${_formatDate(message.startDate!)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.green[50],
                    ),
                  if (message.endDate != null)
                    Chip(
                      label: Text(
                        'Fin: ${_formatDate(message.endDate!)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.red[50],
                    ),
                  Chip(
                    label: Text(
                      message.isActive == true ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 10,
                        color: message.isActive == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    backgroundColor: message.isActive == true
                        ? Colors.green[50]
                        : Colors.red[50],
                  ),
                ],
              ),
              // Actions pour l'admin
              if (showActions && (onToggleStatus != null || onDelete != null))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onToggleStatus != null)
                        IconButton(
                          icon: Icon(
                            message.isActive == true
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            color: message.isActive == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () =>
                              onToggleStatus!(!(message.isActive ?? true)),
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'WELCOME':
        return Colors.blue[100]!;
      case 'TIP':
        return Colors.green[100]!;
      case 'MOTIVATION':
        return Colors.orange[100]!;
      case 'ANNOUNCEMENT':
        return Colors.purple[100]!;
      case 'MAINTENANCE':
        return Colors.red[100]!;
      case 'PROMOTION':
        return Colors.yellow[100]!;
      case 'REMINDER':
        return Colors.cyan[100]!;
      case 'UPDATE':
        return Colors.indigo[100]!;
      case 'SECURITY':
        return Colors.red[200]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority <= 3) return Colors.red;
    if (priority <= 5) return Colors.orange;
    if (priority <= 7) return Colors.yellow[700]!;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
