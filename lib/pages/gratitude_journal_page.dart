import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GratitudeJournalPage extends StatefulWidget {
  const GratitudeJournalPage({super.key});

  @override
  State<GratitudeJournalPage> createState() => _GratitudeJournalPageState();
}

class _GratitudeJournalPageState extends State<GratitudeJournalPage> {
  final List<TextEditingController> _controllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  final List<String> _gratitudeEntries = List.filled(3, '');
  DateTime _selectedDate = DateTime.now();

  final List<JournalEntry> _previousEntries = [
    JournalEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      entries: [
        'Ma famille qui me soutient toujours',
        'Le soleil qui brille ce matin',
        'Cette nouvelle opportunité de travail',
      ],
    ),
    JournalEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      entries: [
        'Une bonne nuit de sommeil',
        'Le café du matin',
        'Un message d\'un ami',
      ],
    ),
  ];

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _saveEntry() {
    bool hasEntries = _gratitudeEntries.any((entry) => entry.isNotEmpty);
    if (hasEntries) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrée de gratitude sauvegardée !'),
          backgroundColor: Color(0xFF81C784),
        ),
      );

      // Ajouter aux entrées précédentes
      setState(() {
        _previousEntries.insert(
          0,
          JournalEntry(
            date: _selectedDate,
            entries: _gratitudeEntries.where((e) => e.isNotEmpty).toList(),
          ),
        );

        // Réinitialiser les champs
        for (int i = 0; i < 3; i++) {
          _controllers[i].clear();
          _gratitudeEntries[i] = '';
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez écrire au moins une chose pour laquelle vous êtes reconnaissant',
          ),
          backgroundColor: Color(0xFFFF5252),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal de Gratitude',
          style: TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
        ),
        backgroundColor: const Color(0xFF4A6572),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFF8FBFC),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    color: const Color(0xFF7DBBC3),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Instructions
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 50,
                              color: Color(0xFFFFB6C1),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              '3 choses pour lesquelles vous êtes reconnaissant aujourd\'hui',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                fontFamily: 'OpenSans',
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Prenez un moment pour réfléchir aux aspects positifs de votre journée.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5D6D7E),
                                fontFamily: 'OpenSans',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Champs de saisie
                    ...List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}.',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A6572),
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              onChanged: (value) {
                                setState(
                                  () => _gratitudeEntries[index] = value,
                                );
                              },
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Écrivez ici...',
                                hintStyle: const TextStyle(
                                  fontFamily: 'OpenSans',
                                  color: Color(0xFFBDC3C7),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              style: const TextStyle(
                                fontFamily: 'OpenSans',
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 30),

                    // Bouton de sauvegarde
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A6572),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sauvegarder mon journal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Entrées précédentes
                    if (_previousEntries.isNotEmpty) ...[
                      const Text(
                        'Mes entrées précédentes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                      const SizedBox(height: 20),

                      ..._previousEntries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE d MMMM',
                                      'fr_FR',
                                    ).format(entry.date),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4A6572),
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...entry.entries.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '• ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4A6572),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF5D6D7E),
                                                fontFamily: 'OpenSans',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JournalEntry {
  final DateTime date;
  final List<String> entries;

  JournalEntry({required this.date, required this.entries});
}
