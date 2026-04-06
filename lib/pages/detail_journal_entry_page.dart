import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moodia/models/journal_entry.dart';

class DetailJournalEntryPage extends StatelessWidget {
  final JournalEntry entry;

  const DetailJournalEntryPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        entry.createdAt != null
            ? DateFormat(
              'dd MMM yyyy – HH:mm',
              'fr_FR',
            ).format(entry.createdAt!)
            : 'Date inconnue';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'entrée'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  entry.content,
                  style: const TextStyle(fontFamily: 'OpenSans', fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
