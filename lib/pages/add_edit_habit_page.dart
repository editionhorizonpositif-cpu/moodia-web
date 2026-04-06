// lib/pages/add_edit_habit_page.dart
import 'dart:convert'; // Ajoutez cet import
import 'package:flutter/foundation.dart'; // Ajoutez cet import pour kDebugMode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/habit_api_service.dart';

class AddEditHabitPage extends StatefulWidget {
  final Habit? habit;

  const AddEditHabitPage({super.key, this.habit});

  @override
  State<AddEditHabitPage> createState() => _AddEditHabitPageState();
}

class _AddEditHabitPageState extends State<AddEditHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final HabitApiService _habitService = HabitApiService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _goalCountController;

  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  HabitCategory _selectedCategory = HabitCategory.autres;
  List<int> _selectedDays = [];
  TimeOfDay? _selectedReminderTime;
  Color? _selectedColor;
  String? _selectedIcon;

  bool _isLoading = false;

  // Modifiez _availableColors pour utiliser des valeurs qui tiennent dans int
  final List<Color> _availableColors = [
    Color(0xFF1976D2), // Bleu - 4280271314
    Color(0xFF388E3C), // Vert - 4283211532
    Color(0xFFF57C00), // Orange - 4294926336 (toujours trop grand!)
    Color(0xFF7B1FA2), // Violet - 4284490146
    Color(0xFFD32F2F), // Rouge - 4287299583
    Color(0xFF00796B), // Vert foncé - 4278248555
    Color(0xFF5D4037), // Marron - 4285418807
    Color(0xFF616161), // Gris - 4286210416
  ];

  final Map<String, IconData> _availableIcons = {
    'fitness_center': Icons.fitness_center,
    'self_improvement': Icons.self_improvement,
    'work': Icons.work,
    'people': Icons.people,
    'restaurant': Icons.restaurant,
    'bedtime': Icons.bedtime,
    'book': Icons.book,
    'attach_money': Icons.attach_money,
    'water_drop': Icons.water_drop,
    'directions_walk': Icons.directions_walk,
    'spa': Icons.spa,
    'local_cafe': Icons.local_cafe,
  };

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _goalCountController = TextEditingController(
      text: (widget.habit?.goalCount ?? 1).toString(),
    );

    if (widget.habit != null) {
      _selectedFrequency = widget.habit!.frequency;
      _selectedCategory = widget.habit!.category;
      _selectedDays = widget.habit!.customDays ?? [];
      _selectedReminderTime = widget.habit!.reminderTime;
      _selectedColor = widget.habit!.color;
      _selectedIcon = widget.habit!.icon;
    } else {
      _selectedColor = _availableColors[0];
      _selectedIcon = _availableIcons.keys.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalCountController.dispose();
    super.dispose();
  }

  // Méthodes de mapping pour convertir en majuscules
  String _mapFrequencyToUpperCase(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'DAILY';
      case HabitFrequency.weekly:
        return 'WEEKLY';
      case HabitFrequency.monthly:
        return 'MONTHLY';
      case HabitFrequency.custom:
        return 'CUSTOM';
    }
  }

  String _mapCategoryToUpperCase(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return 'SANTE_PHYSIQUE';
      case HabitCategory.mentalBienEtre:
        return 'MENTAL_BIEN_ETRE';
      case HabitCategory.productivite:
        return 'PRODUCTIVITE';
      case HabitCategory.relations:
        return 'RELATIONS';
      case HabitCategory.alimentation:
        return 'ALIMENTATION';
      case HabitCategory.sommeil:
        return 'SOMMEIL';
      case HabitCategory.loisirs:
        return 'LOISIRS';
      case HabitCategory.finance:
        return 'FINANCE';
      case HabitCategory.autres:
        return 'AUTRES';
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Utilisez les méthodes de mapping
      final frequencyValue = _mapFrequencyToUpperCase(_selectedFrequency);
      final categoryValue = _mapCategoryToUpperCase(_selectedCategory);

      // Format ISO 8601 pour LocalTime (HH:MM:SS)
      String? reminderTimeString;
      if (_selectedReminderTime != null) {
        final hour = _selectedReminderTime!.hour.toString().padLeft(2, '0');
        final minute = _selectedReminderTime!.minute.toString().padLeft(2, '0');
        reminderTimeString = '$hour:$minute:00';
      }

      final habitData = {
        'userId': userId, // Long dans le DTO
        'name': _nameController.text,
        'description': _descriptionController.text,
        'frequency': frequencyValue,
        'category': categoryValue,
        'goalCount': int.tryParse(_goalCountController.text) ?? 1,
        // Utilisez une valeur de couleur très petite pour tester
        'color': _getSafeColorValue(_selectedColor) ?? 255,
        'icon': _selectedIcon,
        'customDays': _selectedDays.isNotEmpty ? _selectedDays : null,
        // LocalTime format: "HH:MM:SS"
        'reminderTime': reminderTimeString,
        'startDate': DateTime.now().toIso8601String(),
        'isActive': true,
        'isTemplate': false,
      };

      // DEBUG
      if (kDebugMode) {
        print('🎯 Envoi des données CORRIGÉES:');
        print('📝 userId: $userId');
        print('📝 frequency: $frequencyValue');
        print('📝 category: $categoryValue');
        print('📝 reminderTime: $reminderTimeString');
        print('📝 color: ${habitData['color']}');
        print('📝 Données JSON: ${jsonEncode(habitData)}');
      }

      if (widget.habit?.id != null) {
        await _habitService.updateHabit(widget.habit!.id!, habitData);
      } else {
        await _habitService.createHabit(habitData);
      }

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.habit != null
                ? 'Habitude modifiée avec succès'
                : 'Habitude créée avec succès',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );

      if (kDebugMode) {
        print('❌ Erreur détaillée: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Méthode pour obtenir une valeur de couleur sûre
  int? _getSafeColorValue(Color? color) {
    if (color == null) return 255; // Valeur par défaut

    // Utilisez une valeur très petite qui tient dans int Java
    // ou utilisez seulement les bits RGB (sans alpha)
    final rgbOnly = color.value & 0x00FFFFFF;

    // Vérifiez que c'est dans la plage Java int
    if (rgbOnly <= 2147483647) {
      return rgbOnly;
    }

    // Si toujours trop grand, retournez une valeur fixe petite
    return 255; // Rouge vif simple
  }

  // Méthode pour convertir Color en int 24 bits (RGB seulement)
  int? _colorToSafeInt(Color? color) {
    if (color == null) return null;

    // Utilisez seulement les bits RGB (ignorez alpha)
    // 0xFF pour alpha fixe (complètement opaque)
    final rgbOnly = 0xFF000000 | (color.value & 0x00FFFFFF);

    // Vérifiez que c'est dans la plage
    if (rgbOnly <= 2147483647) {
      return rgbOnly;
    }

    // Si toujours trop grand, utilisez une valeur fixe
    return 4278190335; // Noir
  }

  void _showFrequencySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sélectionner la fréquence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...HabitFrequency.values.map((frequency) {
              return ListTile(
                leading: Icon(_getFrequencyIcon(frequency)),
                title: Text(_getFrequencyText(frequency)),
                trailing: _selectedFrequency == frequency
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _selectedFrequency = frequency);
                  if (frequency != HabitFrequency.weekly &&
                      frequency != HabitFrequency.custom) {
                    _selectedDays.clear();
                  }
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sélectionner la catégorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: HabitCategory.values.length,
                itemBuilder: (context, index) {
                  final category = HabitCategory.values[index];
                  final isSelected = _selectedCategory == category;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getCategoryColor(category).withOpacity(0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getCategoryColor(category)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCategoryTextShort(category),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(category),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDaySelector() {
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner les jours'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final isSelected = _selectedDays.contains(index);
            return FilterChip(
              label: Text(dayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(index);
                  } else {
                    _selectedDays.remove(index);
                  }
                });
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableColors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedColor == color
                        ? Colors.black
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _selectedColor == color
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une icône'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final iconName = _availableIcons.keys.elementAt(index);
              final iconData = _availableIcons.values.elementAt(index);
              final isSelected = _selectedIcon == iconName;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIcon = iconName);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    color: isSelected ? Colors.blue : Colors.grey[700],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final initialTime =
        _selectedReminderTime ?? const TimeOfDay(hour: 9, minute: 0);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      setState(() => _selectedReminderTime = pickedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.habit != null ? 'Modifier l\'habitude' : 'Nouvelle habitude',
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveHabit,
            icon: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'habitude',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnelle)',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Fréquence
                    ListTile(
                      leading: const Icon(Icons.repeat),
                      title: const Text('Fréquence'),
                      subtitle: Text(_getFrequencyText(_selectedFrequency)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showFrequencySelector,
                    ),
                    const SizedBox(height: 8),

                    // Jours personnalisés (si hebdomadaire ou personnalisé)
                    if (_selectedFrequency == HabitFrequency.weekly ||
                        _selectedFrequency == HabitFrequency.custom)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Jours'),
                            subtitle: Text(
                              _selectedDays.isEmpty
                                  ? 'Aucun jour sélectionné'
                                  : _selectedDays
                                        .map((day) => _getDayName(day))
                                        .join(', '),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _showDaySelector,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Catégorie
                    ListTile(
                      leading: Icon(_getCategoryIcon(_selectedCategory)),
                      title: const Text('Catégorie'),
                      subtitle: Text(_getCategoryText(_selectedCategory)),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showCategorySelector,
                    ),
                    const SizedBox(height: 8),

                    // Objectif
                    TextFormField(
                      controller: _goalCountController,
                      decoration: const InputDecoration(
                        labelText: 'Objectif (nombre de fois)',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un objectif';
                        }
                        final count = int.tryParse(value);
                        if (count == null || count < 1) {
                          return 'L\'objectif doit être un nombre positif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Couleur
                    ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: const Text('Couleur'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showColorPicker,
                    ),
                    const SizedBox(height: 8),

                    // Icône
                    ListTile(
                      leading: Icon(
                        _selectedIcon != null
                            ? _availableIcons[_selectedIcon]
                            : Icons.help,
                      ),
                      title: const Text('Icône'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showIconPicker,
                    ),
                    const SizedBox(height: 8),

                    // Rappel
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Rappel'),
                      subtitle: Text(
                        _selectedReminderTime != null
                            ? '${_selectedReminderTime!.format(context)}'
                            : 'Aucun rappel',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _selectReminderTime,
                    ),
                    const SizedBox(height: 8),

                    // Bouton de suppression pour l'édition
                    if (widget.habit != null)
                      Column(
                        children: [
                          const SizedBox(height: 32),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _deleteHabit(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.delete),
                              label: const Text('Supprimer cette habitude'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'habitude'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette habitude ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _habitService.deleteHabit(widget.habit!.id!);
        if (!mounted) return;

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habitude supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper methods
  IconData _getFrequencyIcon(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return Icons.today;
      case HabitFrequency.weekly:
        return Icons.date_range;
      case HabitFrequency.monthly:
        return Icons.calendar_month;
      case HabitFrequency.custom:
        return Icons.edit_calendar;
    }
  }

  String _getFrequencyText(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Tous les jours';
      case HabitFrequency.weekly:
        return 'Hebdomadaire';
      case HabitFrequency.monthly:
        return 'Mensuel';
      case HabitFrequency.custom:
        return 'Personnalisé';
    }
  }

  Color _getCategoryColor(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return Colors.blue;
      case HabitCategory.mentalBienEtre:
        return Colors.purple;
      case HabitCategory.productivite:
        return Colors.green;
      case HabitCategory.relations:
        return Colors.pink;
      case HabitCategory.alimentation:
        return Colors.orange;
      case HabitCategory.sommeil:
        return Colors.indigo;
      case HabitCategory.loisirs:
        return Colors.cyan;
      case HabitCategory.finance:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return Icons.fitness_center;
      case HabitCategory.mentalBienEtre:
        return Icons.self_improvement;
      case HabitCategory.productivite:
        return Icons.work;
      case HabitCategory.relations:
        return Icons.people;
      case HabitCategory.alimentation:
        return Icons.restaurant;
      case HabitCategory.sommeil:
        return Icons.bedtime;
      case HabitCategory.loisirs:
        return Icons.sports_esports;
      case HabitCategory.finance:
        return Icons.attach_money;
      default:
        return Icons.check_circle;
    }
  }

  String _getCategoryText(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return 'Santé physique';
      case HabitCategory.mentalBienEtre:
        return 'Bien-être mental';
      case HabitCategory.productivite:
        return 'Productivité';
      case HabitCategory.relations:
        return 'Relations sociales';
      case HabitCategory.alimentation:
        return 'Alimentation';
      case HabitCategory.sommeil:
        return 'Sommeil';
      case HabitCategory.loisirs:
        return 'Loisirs';
      case HabitCategory.finance:
        return 'Finances';
      default:
        return 'Autre';
    }
  }

  String _getCategoryTextShort(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return 'Santé';
      case HabitCategory.mentalBienEtre:
        return 'Mental';
      case HabitCategory.productivite:
        return 'Prod.';
      case HabitCategory.relations:
        return 'Social';
      case HabitCategory.alimentation:
        return 'Food';
      case HabitCategory.sommeil:
        return 'Sommeil';
      case HabitCategory.loisirs:
        return 'Loisirs';
      case HabitCategory.finance:
        return 'Finances';
      default:
        return 'Autre';
    }
  }

  String _getDayName(int dayIndex) {
    final dayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return dayNames[dayIndex];
  }
}
