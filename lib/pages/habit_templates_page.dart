// lib/pages/habit_templates_page.dart (version mise à jour)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/habit_api_service.dart';
import 'add_edit_habit_page.dart';

class HabitTemplatesPage extends StatefulWidget {
  const HabitTemplatesPage({super.key});

  @override
  State<HabitTemplatesPage> createState() => _HabitTemplatesPageState();
}

class _HabitTemplatesPageState extends State<HabitTemplatesPage> {
  final HabitApiService _habitService = HabitApiService();
  HabitCategory? _selectedCategory;
  String _searchQuery = '';
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      _templates = await _habitService.getHabitTemplates();
    } catch (e) {
      // Fallback aux templates locaux en cas d'erreur
      _templates = _getFallbackTemplates();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTemplates {
    return _templates.where((template) {
      final category = HabitCategory.values.firstWhere(
        (c) => c.name == (template['category'] ?? 'autres'),
        orElse: () => HabitCategory.autres,
      );

      final matchesCategory =
          _selectedCategory == null || category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (template['name'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          ((template['description'] as String?) ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Modifiez _addTemplateToHabits()
  Future<void> _addTemplateToHabits(Map<String, dynamic> template) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // ✅ AJOUTEZ le userId dans les données
      final habitData = {
        'userId': userId, // <-- CE CHAMP EST OBLIGATOIRE
        'name': template['name'],
        'description': template['description'],
        'frequency': template['frequency'],
        'category': template['category'],
        'goalCount': template['goalCount'] ?? 1,
        'customDays': template['customDays'],
        'reminderHour': template['reminderHour'],
        'reminderMinute': template['reminderMinute'],
        'color': template['color'],
        'icon': template['icon'],
        'isActive': true,
        'isTemplate': false,
        'startDate': DateTime.now().toIso8601String(),
      };

      // Nettoyez les données (retirez les valeurs null)
      habitData.removeWhere((key, value) => value == null);

      await _habitService.createHabit(habitData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${template['name']}" ajouté à vos habitudes'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showTemplateDetails(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TemplateDetailsSheet(
        template: template,
        onAdd: () => _addTemplateToHabits(template),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('Toutes'),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              setState(() => _selectedCategory = null);
            },
          ),
          ...HabitCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(_getCategoryTextShort(category)),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(
                    () => _selectedCategory = selected ? category : null,
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final color = template['color'] != null
        ? Color(template['color'] as int)
        : _getCategoryColor(
            HabitCategory.values.firstWhere(
              (c) => c.name == (template['category'] ?? 'autres'),
              orElse: () => HabitCategory.autres,
            ),
          );

    final frequency = HabitFrequency.values.firstWhere(
      (f) => f.name == (template['frequency'] ?? 'daily'),
      orElse: () => HabitFrequency.daily,
    );

    final category = HabitCategory.values.firstWhere(
      (c) => c.name == (template['category'] ?? 'autres'),
      orElse: () => HabitCategory.autres,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTemplateDetails(template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconFromName(template['icon'] as String?),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template['description'] as String? ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          _getFrequencyText(frequency),
                          _getFrequencyIcon(frequency),
                          color,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          _getCategoryTextShort(category),
                          _getCategoryIcon(category),
                          color,
                        ),
                        if (template['goalCount'] != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            '${template['goalCount']}x',
                            Icons.flag,
                            color,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                onPressed: () => _addTemplateToHabits(template),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'Aucun template trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Essayez avec d\'autres critères de recherche',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _searchQuery = '';
                });
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 20),
          Text(
            'Chargement des templates...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Bibliothèque d\'habitudes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une habitude...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                _buildCategoryChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredTemplates.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filteredTemplates.length,
                          itemBuilder: (context, index) {
                            return _buildTemplateCard(
                              _filteredTemplates[index],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddEditHabitPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Créer personnalisée'),
      ),
    );
  }

  // Helper methods
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

  String _getFrequencyText(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Quotidien';
      case HabitFrequency.weekly:
        return 'Hebdo';
      case HabitFrequency.monthly:
        return 'Mensuel';
      case HabitFrequency.custom:
        return 'Perso';
    }
  }

  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.check_circle;

    final iconMap = {
      'fitness_center': Icons.fitness_center,
      'self_improvement': Icons.self_improvement,
      'work': Icons.work,
      'people': Icons.people,
      'restaurant': Icons.restaurant,
      'bedtime': Icons.bedtime,
      'book': Icons.book,
      'attach_money': Icons.attach_money,
      'local_cafe': Icons.local_cafe,
      'water_drop': Icons.water_drop,
      'directions_walk': Icons.directions_walk,
      'spa': Icons.spa,
    };

    return iconMap[iconName] ?? Icons.check_circle;
  }

  List<Map<String, dynamic>> _getFallbackTemplates() {
    return [
      {
        'id': 1,
        'name': 'Méditation matinale',
        'description':
            '10 minutes de méditation pour commencer la journée en pleine conscience',
        'frequency': 'daily',
        'category': 'mentalBienEtre',
        'goalCount': 1,
        'color': Colors.purple.value,
        'icon': 'self_improvement',
      },
      {
        'id': 2,
        'name': 'Boire 2L d\'eau',
        'description':
            'Maintenir une bonne hydratation tout au long de la journée',
        'frequency': 'daily',
        'category': 'santePhysique',
        'goalCount': 8,
        'color': Colors.blue.value,
        'icon': 'water_drop',
      },
      {
        'id': 3,
        'name': 'Marche quotidienne',
        'description':
            '30 minutes de marche pour maintenir une activité physique régulière',
        'frequency': 'daily',
        'category': 'santePhysique',
        'goalCount': 1,
        'color': Colors.green.value,
        'icon': 'directions_walk',
      },
      {
        'id': 4,
        'name': 'Journal de gratitude',
        'description':
            'Écrire 3 choses pour lesquelles on est reconnaissant chaque soir',
        'frequency': 'daily',
        'category': 'mentalBienEtre',
        'goalCount': 3,
        'color': Colors.amber.value,
        'icon': 'book',
      },
      {
        'id': 5,
        'name': 'Lecture avant le coucher',
        'description':
            '20 minutes de lecture pour détendre l\'esprit avant de dormir',
        'frequency': 'daily',
        'category': 'loisirs',
        'goalCount': 1,
        'color': Colors.indigo.value,
        'icon': 'book',
      },
      {
        'id': 6,
        'name': 'Séance de stretching',
        'description': '15 minutes d\'étirements pour maintenir la souplesse',
        'frequency': 'custom',
        'category': 'santePhysique',
        'goalCount': 3,
        'customDays': [1, 3, 5],
        'color': Colors.orange.value,
        'icon': 'fitness_center',
      },
    ];
  }
}

class TemplateDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onAdd;

  const TemplateDetailsSheet({
    super.key,
    required this.template,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final color = template['color'] != null
        ? Color(template['color'] as int)
        : Colors.teal;

    final frequency = HabitFrequency.values.firstWhere(
      (f) => f.name == (template['frequency'] ?? 'daily'),
      orElse: () => HabitFrequency.daily,
    );

    final category = HabitCategory.values.firstWhere(
      (c) => c.name == (template['category'] ?? 'autres'),
      orElse: () => HabitCategory.autres,
    );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconFromName(template['icon'] as String?),
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    template['name'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (template['description'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template['description'] as String,
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            const Text(
              'Détails',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),

            _buildDetailRow('Catégorie', _getCategoryText(category)),
            _buildDetailRow('Fréquence', _getFrequencyText(frequency)),
            if (template['goalCount'] != null)
              _buildDetailRow('Objectif', '${template['goalCount']} fois'),

            if (frequency == HabitFrequency.custom &&
                template['customDays'] != null)
              _buildDetailRow(
                'Jours',
                _getDaysText(template['customDays'] as List<dynamic>),
              ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onAdd();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Ajouter à mes habitudes',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
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

  String _getFrequencyText(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Tous les jours';
      case HabitFrequency.weekly:
        return 'Une fois par semaine';
      case HabitFrequency.monthly:
        return 'Une fois par mois';
      case HabitFrequency.custom:
        return 'Jours personnalisés';
    }
  }

  String _getDaysText(List<dynamic> days) {
    final dayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final selectedDays = days.map((index) => dayNames[index as int]).toList();
    return selectedDays.join(', ');
  }

  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.check_circle;

    final iconMap = {
      'fitness_center': Icons.fitness_center,
      'self_improvement': Icons.self_improvement,
      'work': Icons.work,
      'people': Icons.people,
      'restaurant': Icons.restaurant,
      'bedtime': Icons.bedtime,
      'book': Icons.book,
      'attach_money': Icons.attach_money,
      'local_cafe': Icons.local_cafe,
      'water_drop': Icons.water_drop,
      'directions_walk': Icons.directions_walk,
      'spa': Icons.spa,
    };

    return iconMap[iconName] ?? Icons.check_circle;
  }
}
