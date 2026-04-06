// lib/pages/habits_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/habit_api_service.dart';
import 'add_edit_habit_page.dart';
import 'habit_stats_page.dart';
import 'habit_templates_page.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  Future<List<Habit>>? _habitsFuture;
  final HabitApiService _habitService = HabitApiService();
  List<Habit> _allHabits = [];
  List<Habit> _filteredHabits = [];
  HabitCategory? _selectedCategory;
  HabitFrequency? _selectedFrequency;
  bool _showActiveOnly = true;
  String _searchQuery = '';
  bool _isRefreshing = false;
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabits();
    });
  }

  Future<void> _loadHabits() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (!mounted) return;

      setState(() {
        _habitsFuture = _habitService.getHabitsByUser(userId);
        _isRefreshing = true;
      });

      final habits = await _habitsFuture!;

      if (mounted) {
        setState(() {
          _allHabits = habits;
          _filteredHabits = habits;
          _isRefreshing = false;
          _initialLoadComplete = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _initialLoadComplete = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshHabits() async {
    if (_isRefreshing) return;

    await _loadHabits();
    _applyFilters();
  }

  void _applyFilters() {
    if (!_initialLoadComplete) return;

    final filtered = _allHabits.where((habit) {
      final matchesCategory =
          _selectedCategory == null || habit.category == _selectedCategory;
      final matchesFrequency =
          _selectedFrequency == null || habit.frequency == _selectedFrequency;
      final matchesActive = !_showActiveOnly || habit.isActive;
      final matchesSearch =
          _searchQuery.isEmpty ||
          habit.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (habit.description ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      return matchesCategory &&
          matchesFrequency &&
          matchesActive &&
          matchesSearch;
    }).toList();

    if (mounted) {
      setState(() {
        _filteredHabits = filtered;
      });
    }
  }

  Future<void> _toggleHabitCompletion(Habit habit) async {
    try {
      // Mise à jour locale optimiste
      setState(() {
        final index = _allHabits.indexWhere((h) => h.id == habit.id);
        if (index != -1) {
          final now = DateTime.now();
          final isCompletedToday = habit.isCompletedToday;

          _allHabits[index] = habit.copyWith(
            lastCompleted: isCompletedToday ? null : now,
            currentStreak: isCompletedToday
                ? max(0, habit.currentStreak - 1)
                : habit.currentStreak + 1,
            bestStreak: isCompletedToday
                ? habit.bestStreak
                : max(habit.bestStreak, (habit.currentStreak + 1)),
          );
          _applyFilters();
        }
      });

      // Appeler l'API
      await _habitService.toggleHabitCompletion(habit.id!);

      if (!habit.isCompletedToday) {
        _showCompletionSnackbar(habit);
      }
    } catch (e) {
      // Rollback en cas d'erreur
      await _refreshHabits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCompletionSnackbar(Habit habit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getCategoryIcon(habit.category), color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bravo! "${habit.name}" complété',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showHabitOptions(Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => HabitOptionsSheet(
        habit: habit,
        onUpdate: _refreshHabits,
        habitService: _habitService,
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final color = habit.color ?? _getCategoryColor(habit.category);
    final isToday = habit.shouldBeCompletedToday();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isToday ? color.withOpacity(0.3) : Colors.transparent,
          width: isToday ? 2 : 0,
        ),
      ),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggleHabitCompletion(habit),
        onLongPress: () => _showHabitOptions(habit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconFromName(habit.icon),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: habit.isActive
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!habit.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'En pause',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getFrequencyText(habit)} • ${_getCategoryText(habit.category)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCompletionToggle(habit, color),
                ],
              ),

              if (habit.description != null && habit.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    habit.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    _buildStreakBadge(habit.currentStreak, 'Série', color),
                    if (habit.bestStreak > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildStreakBadge(
                          habit.bestStreak,
                          'Record',
                          Colors.amber,
                        ),
                      ),
                    const Spacer(),
                    if (habit.goalCount != null && habit.goalCount! > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${habit.goalCount}x/jour',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showHabitOptions(habit),
                      color: Colors.grey[600],
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

  Widget _buildCompletionToggle(Habit habit, Color color) {
    final isCompletedToday = habit.isCompletedToday;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompletedToday
            ? color
            : habit.shouldBeCompletedToday()
            ? Colors.grey[100]
            : Colors.grey[50],
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompletedToday
              ? color
              : habit.shouldBeCompletedToday()
              ? const Color.fromARGB(255, 238, 231, 231)
              : const Color.fromARGB(255, 219, 213, 213),
          width: 2,
        ),
      ),
      child: Center(
        child: isCompletedToday
            ? Icon(Icons.check, color: Colors.white, size: 20)
            : habit.shouldBeCompletedToday()
            ? Icon(Icons.add, color: color, size: 20)
            : Icon(Icons.remove, color: Colors.grey[400], size: 20),
      ),
    );
  }

  Widget _buildReminderBadge(Habit habit) {
    if (habit.reminderTime == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            habit.formattedReminderTime ?? '',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(int streak, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            Icon(Icons.self_improvement, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'Aucune habitude',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Commencez par créer votre première habitude\nou explorez nos suggestions',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddHabit(),
              icon: const Icon(Icons.add),
              label: const Text('Créer une habitude'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _navigateToTemplates(),
              child: const Text('Voir les suggestions'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditHabitPage()),
    );
    if (result == true) await _refreshHabits();
  }

  void _navigateToTemplates() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitTemplatesPage()),
    );
    if (result == true) await _refreshHabits();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltersSheet(
        selectedCategory: _selectedCategory,
        selectedFrequency: _selectedFrequency,
        showActiveOnly: _showActiveOnly,
        onApply: (category, frequency, activeOnly) {
          if (mounted) {
            setState(() {
              _selectedCategory = category;
              _selectedFrequency = frequency;
              _showActiveOnly = activeOnly;
              _applyFilters();
            });
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 2,
              floating: true,
              pinned: true,
              snap: true,
              title: const Text(
                'Mes Habitudes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.insights),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HabitStatsPage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilters,
                ),
                IconButton(
                  icon: const Icon(Icons.lightbulb_outline),
                  onPressed: _navigateToTemplates,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une habitude...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[50],
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
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _navigateToAddHabit,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle habitude'),
      ),
    );
  }

  Widget _buildBody() {
    if (!_initialLoadComplete) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return RefreshIndicator(
      color: Colors.teal,
      onRefresh: _refreshHabits,
      child: _filteredHabits.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHabits.length,
              itemBuilder: (context, index) {
                return _buildHabitCard(_filteredHabits[index]);
              },
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

  String _getCategoryText(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return 'Santé physique';
      case HabitCategory.mentalBienEtre:
        return 'Bien-être mental';
      case HabitCategory.productivite:
        return 'Productivité';
      case HabitCategory.relations:
        return 'Relations';
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

  String _getFrequencyText(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Quotidien';
      case HabitFrequency.weekly:
        return 'Hebdomadaire';
      case HabitFrequency.monthly:
        return 'Mensuel';
      case HabitFrequency.custom:
        return 'Personnalisé';
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
}

class HabitOptionsSheet extends StatelessWidget {
  final Habit habit;
  final VoidCallback onUpdate;
  final HabitApiService habitService;

  const HabitOptionsSheet({
    super.key,
    required this.habit,
    required this.onUpdate,
    required this.habitService,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              habit.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Divider(color: Colors.grey[300]),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Modifier'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditHabitPage(habit: habit),
                ),
              );
              if (result == true) onUpdate();
            },
          ),
          ListTile(
            leading: Icon(
              habit.isActive ? Icons.pause : Icons.play_arrow,
              color: Colors.orange,
            ),
            title: Text(habit.isActive ? 'Mettre en pause' : 'Activer'),
            onTap: () async {
              try {
                await habitService.updateHabit(habit.id!, {
                  'isActive': !habit.isActive,
                });
                Navigator.pop(context);
                onUpdate();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.insights, color: Colors.purple),
            title: const Text('Statistiques'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HabitStatsPage(habitId: habit.id),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Supprimer'),
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'habitude'),
        content: Text('Supprimer définitivement "${habit.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await habitService.deleteHabit(habit.id!);
                Navigator.pop(context); // Fermer dialog
                Navigator.pop(context); // Fermer bottom sheet
                onUpdate();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Habitude supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class FiltersSheet extends StatefulWidget {
  final HabitCategory? selectedCategory;
  final HabitFrequency? selectedFrequency;
  final bool showActiveOnly;
  final Function(HabitCategory?, HabitFrequency?, bool) onApply;

  const FiltersSheet({
    super.key,
    this.selectedCategory,
    this.selectedFrequency,
    required this.showActiveOnly,
    required this.onApply,
  });

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late HabitCategory? _category;
  late HabitFrequency? _frequency;
  late bool _activeOnly;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _frequency = widget.selectedFrequency;
    _activeOnly = widget.showActiveOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          const Text(
            'Catégorie',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Wrap(
            spacing: 8,
            children: HabitCategory.values.map((category) {
              final isSelected = _category == category;
              return FilterChip(
                label: Text(_getCategoryTextShort(category)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _category = selected ? category : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text(
            'Fréquence',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Wrap(
            spacing: 8,
            children: HabitFrequency.values.map((frequency) {
              final isSelected = _frequency == frequency;
              return FilterChip(
                label: Text(_getFrequencyText(frequency)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _frequency = selected ? frequency : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Afficher uniquement les actives'),
            value: _activeOnly,
            onChanged: (value) => setState(() => _activeOnly = value),
          ),

          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _frequency = null;
                      _activeOnly = true;
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_category, _frequency, _activeOnly);
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      default:
        return category.name;
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
}
