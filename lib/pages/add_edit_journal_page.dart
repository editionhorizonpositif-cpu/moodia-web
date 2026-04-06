import 'package:flutter/material.dart';
import 'package:moodia/models/journal_entry.dart';
import 'package:moodia/services/journal_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddEditJournalPage extends StatefulWidget {
  final JournalEntry? entry;
  final bool isEditing;
  final EntryType? entryType;

  const AddEditJournalPage({
    super.key,
    this.entry,
    this.isEditing = false,
    this.entryType,
  });

  @override
  State<AddEditJournalPage> createState() => _AddEditJournalPageState();
}

class _AddEditJournalPageState extends State<AddEditJournalPage> {
  final JournalApiService _journalService = JournalApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  EntryType _selectedType = EntryType.GENERAL;
  int? _moodRating;
  bool _isPrivate = true;
  List<String> _tags = [];
  bool _isSaving = false;

  final List<String> _suggestedTags = [
    'bonheur',
    'tristesse',
    'colère',
    'amour',
    'stress',
    'travail',
    'famille',
    'amis',
    'santé',
    'loisirs',
    'croissance',
    'défi',
    'succès',
    'apprentissage',
    'nature',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.isEditing && widget.entry != null) {
      final entry = widget.entry!;
      _titleController.text = entry.title ?? '';
      _contentController.text = entry.content;
      _selectedType = entry.entryType;
      _moodRating = entry.moodRating;
      _isPrivate = entry.isPrivate;
      _tags = entry.tags.toList();
    } else if (widget.entryType != null) {
      _selectedType = widget.entryType!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (widget.isEditing && widget.entry != null) {
        // Mise à jour
        await _journalService.updateEntry(
          id: widget.entry!.id!,
          userId: userId,
          request: UpdateJournalEntryRequest(
            content: _contentController.text.trim(),
            title: _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : null,
            moodRating: _moodRating,
            entryType: _selectedType.name,
            isPrivate: _isPrivate,
            tags: _tags,
          ),
        );
      } else {
        // Création
        await _journalService.createEntry(
          CreateJournalEntryRequest(
            content: _contentController.text.trim(),
            title: _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : null,
            moodRating: _moodRating,
            entryType: _selectedType.name,
            isPrivate: _isPrivate,
            tags: _tags,
          ),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Entrée modifiée avec succès'
                : 'Entrée créée avec succès',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isSaving = false;
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.isEditing ? 'Modifier l\'entrée' : 'Nouvelle entrée'),
      actions: [
        IconButton(
          onPressed: _isSaving ? null : _saveEntry,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          tooltip: 'Enregistrer',
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'entrée',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EntryType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type;
                });
              },
              avatar: Icon(type.icon, size: 18, color: type.color),
              backgroundColor: type.color.withOpacity(0.1),
              selectedColor: type.color.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? type.color : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Humeur du moment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(10, (index) {
            final rating = index + 1;
            final isSelected = _moodRating == rating;
            final icon = _getMoodIcon(rating);
            final color = _getMoodColor(rating);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _moodRating = rating;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(isSelected ? 1 : 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: isSelected ? Colors.white : color),
                    const SizedBox(height: 4),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  IconData _getMoodIcon(int rating) {
    if (rating >= 9) return Icons.sentiment_very_satisfied;
    if (rating >= 7) return Icons.sentiment_satisfied;
    if (rating >= 5) return Icons.sentiment_neutral;
    if (rating >= 3) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  Color _getMoodColor(int rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.lightGreen;
    if (rating >= 4) return Colors.orange;
    if (rating >= 2) return Colors.orangeAccent;
    return Colors.red;
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Champ de saisie pour ajouter des tags
        TextField(
          controller: _tagController,
          decoration: InputDecoration(
            hintText: 'Ajouter un tag...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final tag = _tagController.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                    _tagController.clear();
                  });
                }
              },
            ),
          ),
          onSubmitted: (value) {
            final tag = value.trim();
            if (tag.isNotEmpty && !_tags.contains(tag)) {
              setState(() {
                _tags.add(tag);
                _tagController.clear();
              });
            }
          },
        ),
        const SizedBox(height: 12),
        // Tags suggérés
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _suggestedTags.map((tag) {
            return FilterChip(
              label: Text(tag),
              selected: _tags.contains(tag),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _tags.add(tag);
                  } else {
                    _tags.remove(tag);
                  }
                });
              },
              backgroundColor: Colors.blue.withOpacity(0.1),
              selectedColor: Colors.blue.withOpacity(0.3),
              labelStyle: const TextStyle(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Tags sélectionnés
        if (_tags.isNotEmpty) ...[
          const Text(
            'Tags sélectionnés :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag, style: const TextStyle(fontSize: 13)),
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteIconColor: Colors.deepPurple,
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildMoodSelector(),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre (optionnel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                      ),
                      maxLength: 200,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Contenu*',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                      ),
                      maxLines: 10,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le contenu est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTagsSelector(),
                    const SizedBox(height: 24),
                    // Section confidentialité
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPrivate ? Icons.lock : Icons.public,
                            color: _isPrivate
                                ? Colors.deepPurple
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPrivate ? 'Privé' : 'Public',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _isPrivate
                                      ? 'Visible uniquement par vous'
                                      : 'Visible par tous les utilisateurs',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPrivate,
                            onChanged: (value) {
                              setState(() {
                                _isPrivate = value;
                              });
                            },
                            activeColor: Colors.deepPurple,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Statistiques
                    if (_contentController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              icon: Icons.text_fields,
                              value: _contentController.text.length.toString(),
                              label: 'Caractères',
                            ),
                            _buildStatItem(
                              icon: Icons.format_list_bulleted,
                              value: _contentController.text
                                  .split(RegExp(r'\s+'))
                                  .where((word) => word.isNotEmpty)
                                  .length
                                  .toString(),
                              label: 'Mots',
                            ),
                            _buildStatItem(
                              icon: Icons.timer,
                              value:
                                  '${(_contentController.text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length / 200).ceil()}',
                              label: 'Minutes',
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Bouton d'enregistrement
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Enregistrement...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isEditing
                                        ? Icons.save_as
                                        : Icons.add,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.isEditing
                                        ? 'Mettre à jour l\'entrée'
                                        : 'Créer l\'entrée',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
