/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge.dart';
import '../../models/challenge_request_dtos.dart';
import '../../widgets/challenge_difficulty_indicator.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AddChallengePage extends StatefulWidget {
  const AddChallengePage({super.key});

  @override
  State<AddChallengePage> createState() => _AddChallengePageState();
}

class _AddChallengePageState extends State<AddChallengePage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pointsRewardController = TextEditingController();
  final _xpRewardController = TextEditingController();
  final _durationValueController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _iconController = TextEditingController();
  final _colorCodeController = TextEditingController();

  // Sélections
  int? _selectedCategoryId;
  String _selectedDifficulty = 'MEDIUM';
  String _selectedDurationUnit = 'DAYS';
  int? _vibrationLevel;
  DateTime? _startDate;
  DateTime? _endDate;

  // Booléens
  bool _isFeatured = false;
  bool _isPremium = false;
  bool _hasReminder = false;
  bool _requiresApproval = false;
  String? _reminderFrequency;

  // Tags et prérequis
  final List<String> _tags = [];
  final List<String> _requirements = [];
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();

  // États
  bool _isLoading = false;
  bool _isAdmin = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.currentUser;

    setState(() {
      _isAdmin = user?.isAdmin ?? false;
    });

    if (!_isAdmin && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accès non autorisé'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _pointsRewardController.dispose();
    _xpRewardController.dispose();
    _durationValueController.dispose();
    _maxParticipantsController.dispose();
    _imageUrlController.dispose();
    _iconController.dispose();
    _colorCodeController.dispose();
    _tagController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _addRequirement() {
    if (_requirementController.text.trim().isNotEmpty) {
      setState(() {
        _requirements.add(_requirementController.text.trim());
        _requirementController.clear();
      });
    }
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Construire la requête
      final request = CreateChallengeRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        categoryId: _selectedCategoryId!,
        difficultyLevel: _selectedDifficulty,
        vibrationLevel: _vibrationLevel,
        pointsReward: _pointsRewardController.text.isNotEmpty
            ? int.parse(_pointsRewardController.text)
            : null,
        xpReward: _xpRewardController.text.isNotEmpty
            ? int.parse(_xpRewardController.text)
            : null,
        maxParticipants: _maxParticipantsController.text.isNotEmpty
            ? int.parse(_maxParticipantsController.text)
            : null,
        isFeatured: _isFeatured,
        isPremium: _isPremium,
        tags: _tags.isNotEmpty ? _tags : null,
        requirements: _requirements.isNotEmpty ? _requirements : null,
        startsAt: _startDate,
        endsAt: _endDate,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        icon: _iconController.text.isNotEmpty
            ? _iconController.text.trim()
            : null,
        colorCode: _colorCodeController.text.isNotEmpty
            ? _colorCodeController.text.trim()
            : null,
        reminderFrequency: _hasReminder ? _reminderFrequency : null,
        hasReminder: _hasReminder,
        requiresApproval: _requiresApproval,
        duration: _durationValueController.text.isNotEmpty
            ? DurationRequest(
                value: int.parse(_durationValueController.text),
                unit: _selectedDurationUnit,
              )
            : null,
      );

      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final success = await provider.createChallenge(request);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Défi créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Créer un nouveau défi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Section Informations de base
                  _buildSectionTitle('Informations de base'),
                  const SizedBox(height: 12),

                  // Titre
                  _buildTextField(
                    controller: _titleController,
                    label: 'Titre du défi *',
                    hint: 'Ex: Défi de méditation quotidienne',
                    icon: Icons.title,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le titre est requis';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description *',
                    hint: 'Décrivez le défi en quelques phrases...',
                    icon: Icons.description,
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La description est requise';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Instructions
                  _buildTextField(
                    controller: _instructionsController,
                    label: 'Instructions',
                    hint: 'Instructions détaillées pour réaliser le défi...',
                    icon: Icons.menu_book,
                    maxLines: 6,
                  ),

                  const SizedBox(height: 24),

                  // Section Configuration
                  _buildSectionTitle('Configuration'),
                  const SizedBox(height: 12),

                  // Catégorie
                  _buildCategorySelector(),

                  const SizedBox(height: 16),

                  // Difficulté
                  _buildDifficultySelector(),

                  const SizedBox(height: 16),

                  // Niveau de vibration
                  _buildVibrationSlider(),

                  const SizedBox(height: 16),

                  // Durée
                  _buildDurationFields(),

                  const SizedBox(height: 24),

                  // Section Récompenses
                  _buildSectionTitle('Récompenses'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _pointsRewardController,
                          label: 'Points',
                          hint: '100',
                          icon: Icons.emoji_events,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _xpRewardController,
                          label: 'XP',
                          hint: '50',
                          icon: Icons.star,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section Options
                  _buildSectionTitle('Options'),
                  const SizedBox(height: 12),

                  // Options avancées
                  _buildOptionsCard(),

                  const SizedBox(height: 24),

                  // Section Tags
                  _buildSectionTitle('Tags'),
                  const SizedBox(height: 12),

                  _buildTagsSection(),

                  const SizedBox(height: 24),

                  // Section Prérequis
                  _buildSectionTitle('Prérequis'),
                  const SizedBox(height: 12),

                  _buildRequirementsSection(),

                  const SizedBox(height: 24),

                  // Section Dates
                  _buildSectionTitle('Dates'),
                  const SizedBox(height: 12),

                  _buildDateSection(),

                  const SizedBox(height: 24),

                  // Section Médias
                  _buildSectionTitle('Médias'),
                  const SizedBox(height: 12),

                  _buildMediaSection(),

                  const SizedBox(height: 32),

                  // Bouton de soumission
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DBBC3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Créer le défi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: InputBorder.none,
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF7DBBC3))
                : null,
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, child) {
        final categories = provider.activeCategories;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catégorie *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                if (categories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      return FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? category.id : null;
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: const Color(0xFF7DBBC3).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF7DBBC3),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF7DBBC3)
                              : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        avatar: category.icon != null
                            ? Icon(
                                Icons.category,
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF7DBBC3)
                                    : Colors.grey[500],
                              )
                            : null,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = [
      'BEGINNER',
      'EASY',
      'MEDIUM',
      'HARD',
      'EXPERT',
      'MASTER',
    ];
    final difficultyLabels = {
      'BEGINNER': 'Débutant',
      'EASY': 'Facile',
      'MEDIUM': 'Intermédiaire',
      'HARD': 'Difficile',
      'EXPERT': 'Expert',
      'MASTER': 'Maître',
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Niveau de difficulté *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: difficulties.map((difficulty) {
                final isSelected = _selectedDifficulty == difficulty;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7DBBC3).withOpacity(0.2)
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF7DBBC3)
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: ChallengeDifficultyIndicator(
                            difficulty: difficulty,
                            size: 32,
                            showLabel: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficultyLabels[difficulty]!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? const Color(0xFF7DBBC3)
                              : Colors.grey[600],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibrationSlider() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Niveau de vibration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DBBC3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _vibrationLevel != null
                        ? '${_vibrationLevel}/10'
                        : 'Non défini',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7DBBC3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: (_vibrationLevel ?? 5).toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: const Color(0xFF7DBBC3),
              inactiveColor: Colors.grey[300],
              onChanged: (value) {
                setState(() {
                  _vibrationLevel = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Durée',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _durationValueController,
                    decoration: const InputDecoration(
                      hintText: '30',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _selectedDurationUnit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'MINUTES',
                        child: Text('Minutes'),
                      ),
                      DropdownMenuItem(value: 'HOURS', child: Text('Heures')),
                      DropdownMenuItem(value: 'DAYS', child: Text('Jours')),
                      DropdownMenuItem(value: 'WEEKS', child: Text('Semaines')),
                      DropdownMenuItem(value: 'MONTHS', child: Text('Mois')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDurationUnit = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Défi en vedette'),
              subtitle: const Text('Apparaîtra dans la section "En vedette"'),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
              activeColor: const Color(0xFF7DBBC3),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Défi premium'),
              subtitle: const Text('Réservé aux abonnés premium'),
              value: _isPremium,
              onChanged: (value) {
                setState(() {
                  _isPremium = value;
                });
              },
              activeColor: const Color(0xFF7DBBC3),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Rappels'),
              subtitle: const Text('Activer les rappels pour ce défi'),
              value: _hasReminder,
              onChanged: (value) {
                setState(() {
                  _hasReminder = value;
                  if (!value) _reminderFrequency = null;
                });
              },
              activeColor: const Color(0xFF7DBBC3),
            ),
            if (_hasReminder) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: DropdownButtonFormField<String>(
                  value: _reminderFrequency ?? 'DAILY',
                  decoration: const InputDecoration(
                    labelText: 'Fréquence des rappels',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DAILY', child: Text('Quotidien')),
                    DropdownMenuItem(
                      value: 'WEEKLY',
                      child: Text('Hebdomadaire'),
                    ),
                    DropdownMenuItem(
                      value: 'CUSTOM',
                      child: Text('Personnalisé'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _reminderFrequency = value;
                    });
                  },
                ),
              ),
            ],
            const Divider(),
            SwitchListTile(
              title: const Text('Approbation requise'),
              subtitle: const Text(
                'Les participations doivent être approuvées',
              ),
              value: _requiresApproval,
              onChanged: (value) {
                setState(() {
                  _requiresApproval = value;
                });
              },
              activeColor: const Color(0xFF7DBBC3),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Nombre maximum de participants',
                hintText: '100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people, color: Color(0xFF7DBBC3)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: méditation, bien-être',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF7DBBC3)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.asMap().entries.map((entry) {
                final index = entry.key;
                final tag = entry.value;
                return Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(index),
                  backgroundColor: const Color(0xFF7DBBC3).withOpacity(0.1),
                  deleteIconColor: const Color(0xFF7DBBC3),
                  labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _requirementController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Aucune expérience requise',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addRequirement(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addRequirement,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF7DBBC3)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _requirements.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF7DBBC3),
                    size: 20,
                  ),
                  title: Text(_requirements[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeRequirement(index),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF7DBBC3)),
              title: Text(
                _startDate != null
                    ? 'Début: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'
                    : 'Date de début',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, true),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event_busy, color: Color(0xFF7DBBC3)),
              title: Text(
                _endDate != null
                    ? 'Fin: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                    : 'Date de fin',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajouter une image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de l\'image',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image, color: Color(0xFF7DBBC3)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icône',
                      hintText: 'fas fa-brain',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.emoji_emotions,
                        color: Color(0xFF7DBBC3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _colorCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Couleur',
                      hintText: '#4CAF50',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.color_lens,
                        color: Color(0xFF7DBBC3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/
