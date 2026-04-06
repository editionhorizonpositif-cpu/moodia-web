// lib/pages/journal_home_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moodia/models/journal_entry.dart';
import 'package:moodia/services/journal_api_service.dart';
import 'package:moodia/pages/journal_entry_detail_page.dart';
import 'package:moodia/pages/journal_statistics_page.dart';
import 'package:moodia/pages/add_edit_journal_page.dart';
import 'package:moodia/widgets/journal_entry_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalHomePage extends StatefulWidget {
  const JournalHomePage({super.key});

  @override
  State<JournalHomePage> createState() => _JournalHomePageState();
}

class _JournalHomePageState extends State<JournalHomePage> {
  final JournalApiService _journalService = JournalApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<JournalEntry> _entries = [];
  List<JournalEntry> _cachedEntries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  int? _userId;

  // État de la connexion
  bool _isOnline = true;
  String? _connectionStatus;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Statistiques locales
  int _totalWords = 0;
  int _streak = 0;
  String _searchQuery = '';

  final List<String> _entryTypes = [
    'Tous',
    'Général',
    'Gratitude',
    'Réflexion',
    'Réussite',
  ];

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initializeData();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initializeData() async {
    await _loadUserId(); // Attend la récupération du userId
    await _loadEntries(); // Lance le chargement une fois l'ID disponible
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ========== GESTION DE LA CONNECTIVITÉ ==========
  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(result);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final wasOnline = _isOnline;
      _updateConnectivityStatus(result);
      if (!wasOnline && _isOnline) {
        _syncEntries(); // Synchronisation au retour en ligne
      }
    });
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    setState(() {
      _isOnline = result != ConnectivityResult.none;
      _connectionStatus = _isOnline ? '📶 En ligne' : '📴 Mode hors-ligne';
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    if (kDebugMode) print('👤 UserId chargé : $_userId');
  }

  // ========== GESTION DU CACHE ==========
  Future<void> _saveEntriesToCache(List<JournalEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = entries.map((e) => e.toJson()).toList();
      await prefs.setString('cached_entries_$_userId', jsonEncode(entriesJson));
      if (kDebugMode)
        print('💾 Journal sauvegardé en cache (${entries.length} entrées)');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde cache journal: $e');
    }
  }

  Future<List<JournalEntry>> _loadEntriesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_entries_$_userId');
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isEmpty) return [];

      final entries = <JournalEntry>[];
      for (final json in jsonList) {
        try {
          entries.add(JournalEntry.fromJson(json as Map<String, dynamic>));
        } catch (e) {
          if (kDebugMode) print('⚠️ Entrée invalide dans cache : $e');
        }
      }

      // Si aucune entrée valide, supprimer le cache pour éviter un blocage futur
      if (entries.isEmpty) {
        await prefs.remove('cached_entries_$_userId');
      }

      if (kDebugMode)
        print('📦 Journal chargé depuis cache (${entries.length} entrées)');
      return entries;
    } catch (e) {
      // En cas d'erreur de décodage global, effacer la clé
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_entries_$_userId');
      if (kDebugMode) print('❌ Erreur chargement cache journal: $e');
      return [];
    }
  }

  // ========== SYNCHRONISATION ==========
  Future<void> _syncEntries() async {
    if (!_isOnline || _userId == null) return;
    if (kDebugMode) print('🔄 Synchronisation du journal...');

    try {
      // Récupérer toutes les entrées depuis l'API (paginer jusqu'à la fin)
      List<JournalEntry> allEntries = [];
      int page = 0;
      bool hasMore = true;

      while (hasMore) {
        final pageData = await _journalService.getUserEntries(
          userId: _userId!,
          page: page,
          size: _pageSize,
          sort: 'createdAt,desc',
          forceRefresh: true,
        );
        allEntries.addAll(pageData.entries);
        hasMore = pageData.hasMore;
        page++;
      }

      if (allEntries.isNotEmpty) {
        await _saveEntriesToCache(allEntries);
        if (mounted) {
          setState(() {
            _entries = allEntries;
            _cachedEntries = allEntries;
            _hasMore = false; // On a tout en cache, plus de pagination
            _isLoading = false;
          });
          _updateStatistics();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal synchronisé'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur synchronisation: $e');
    }
  }

  // ========== CHARGEMENT DES ENTRÉES ==========
  Future<void> _loadEntries({bool reset = false}) async {
    if (_userId == null) {
      setState(() {
        _errorMessage = 'Utilisateur non connecté. Veuillez vous reconnecter.';
        _isLoading = false;
      });
      return;
    }
    if (reset) {
      setState(() {
        _currentPage = 0;
        _entries = [];
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    if (_isOnline) {
      try {
        final response = await _journalService.getUserEntries(
          userId: _userId!,
          page: _currentPage,
          size: _pageSize,
          sort: 'createdAt,desc',
          forceRefresh: true,
        );

        if (reset) {
          _cachedEntries = response.entries;
        } else {
          _cachedEntries.addAll(response.entries);
        }

        // Sauvegarde du cache
        await _saveEntriesToCache(_cachedEntries);

        setState(() {
          if (reset) {
            _entries = response.entries;
          } else {
            _entries.addAll(response.entries);
          }
          _hasMore = response.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
          if (!response.hasMore) _currentPage++;
        });
        _updateStatistics();
      } catch (e) {
        if (kDebugMode) print('❌ Erreur chargement en ligne: $e');
        // En cas d'erreur réseau, on utilise le cache
        final cached = await _loadEntriesFromCache();
        if (cached.isNotEmpty) {
          setState(() {
            _entries = cached;
            _cachedEntries = cached;
            _isLoading = false;
            _hasMore = false;
            _errorMessage = null;
          });
          _updateStatistics();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Erreur de chargement. Vérifiez votre connexion.';
          });
        }
      }
    } else {
      // Hors ligne : charger depuis le cache
      final cached = await _loadEntriesFromCache();
      if (cached.isNotEmpty) {
        setState(() {
          _entries = cached;
          _cachedEntries = cached;
          _isLoading = false;
          _hasMore = false;
          _errorMessage = null;
        });
        _updateStatistics();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Mode hors ligne : aucune donnée en cache.';
        });
      }
    }
  }

  Future<void> _loadMoreEntries() async {
    if (_isLoadingMore || !_hasMore || !_isOnline) return;
    setState(() => _isLoadingMore = true);
    await _loadEntries();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEntries();
    }
  }

  Future<void> _refreshEntries() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’actualiser : mode hors ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _syncEntries(); // Recharge tout depuis l'API
  }

  // ========== STATISTIQUES LOCALES ==========
  void _updateStatistics() {
    _totalWords = _entries.fold(0, (sum, e) => sum + (e.wordCount ?? 0));
    _streak = _calculateStreak();
  }

  int _calculateStreak() {
    if (_entries.isEmpty) return 0;
    final sorted = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    int streak = 1;
    DateTime currentDate = sorted.first.createdAt;
    for (final entry in sorted.skip(1)) {
      final difference = currentDate.difference(entry.createdAt).inDays;
      if (difference == 1) {
        streak++;
        currentDate = entry.createdAt;
      } else if (difference > 1) {
        break;
      }
    }
    return streak;
  }

  // ========== ACTIONS UTILISATEUR ==========
  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Cette action est irréversible. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && entry.id != null && _userId != null) {
      try {
        await _journalService.deleteEntry(entry.id!, _userId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrée supprimée'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _entries.removeWhere((e) => e.id == entry.id);
          _cachedEntries.removeWhere((e) => e.id == entry.id);
        });
        await _saveEntriesToCache(_cachedEntries);
        _updateStatistics();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openEntryDetail(JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEntryDetailPage(entry: entry),
      ),
    );
  }

  void _openStatistics() {
    if (_userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JournalStatisticsPage(userId: _userId!),
        ),
      );
    }
  }

  void _openSearch() {
    showSearch(
      context: context,
      delegate: JournalSearchDelegate(_journalService, _userId!),
    );
  }

  void _openFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => JournalFilterBottomSheet(
        onFilterApplied: (filter) {
          // Filtrage local
          setState(() {
            _searchQuery = filter.entryType?.displayName ?? '';
          });
        },
      ),
    );
  }

  Future<void> _openAddEntry({EntryType? entryType}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditJournalPage(entryType: entryType ?? EntryType.GENERAL),
      ),
    );
    if (result == true) await _refreshEntries();
  }

  Future<void> _openEditEntry(JournalEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJournalPage(entry: entry, isEditing: true),
      ),
    );
    if (result == true) await _refreshEntries();
  }

  List<JournalEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    return _entries
        .where((e) => e.entryType.displayName.contains(_searchQuery))
        .toList();
  }

  // ========== WIDGETS UI ==========
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mon Journal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade800,
                      Colors.purple.shade600,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (_isOnline ? Colors.green : Colors.orange)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isOnline ? Colors.green : Colors.orange)
                          .withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi : Icons.offline_bolt,
                        size: 14,
                        color: _isOnline ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOnline ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isOnline ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                tooltip: 'Rechercher',
              ),
              IconButton(
                onPressed: _openFilterMenu,
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtrer',
              ),
              IconButton(
                onPressed: _openStatistics,
                icon: const Icon(Icons.insights),
                tooltip: 'Statistiques',
              ),
            ],
          ),

          // Statistiques rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple.shade800.withOpacity(0.1),
                      Colors.purple.shade600.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: Icons.book,
                      value: _entries.length.toString(),
                      label: 'Entrées',
                    ),
                    _buildStatItem(
                      icon: Icons.edit_note,
                      value: _totalWords.toString(),
                      label: 'Mots',
                    ),
                    _buildStatItem(
                      icon: Icons.timeline,
                      value: _streak.toString(),
                      label: 'Jours',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions rapides
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildQuickActions(),
            ),
          ),

          // Contenu principal
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshEntries,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredEntries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Commencez votre voyage',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Écrivez votre première entrée pour explorer vos pensées',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => _openAddEntry(),
                      icon: const Icon(Icons.add),
                      label: const Text('Première entrée'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _filteredEntries.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final entry = _filteredEntries[index];
                  return JournalEntryCard(
                    entry: entry,
                    onTap: () => _openEntryDetail(entry),
                    onDelete: () => _deleteEntry(entry),
                    onEdit: () => _openEditEntry(entry),
                  );
                },
                childCount:
                    _filteredEntries.length + (_hasMore && _isOnline ? 1 : 0),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntry(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle entrée'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.deepPurple),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: Icons.favorite,
          label: 'Gratitude',
          color: EntryType.GRATITUDE.color,
          onTap: () => _openAddEntry(entryType: EntryType.GRATITUDE),
        ),
        _buildQuickActionButton(
          icon: Icons.psychology,
          label: 'Réflexion',
          color: EntryType.REFLECTION.color,
          onTap: () => _openAddEntry(entryType: EntryType.REFLECTION),
        ),
        _buildQuickActionButton(
          icon: Icons.star,
          label: 'Réussite',
          color: EntryType.ACHIEVEMENT.color,
          onTap: () => _openAddEntry(entryType: EntryType.ACHIEVEMENT),
        ),
        _buildQuickActionButton(
          icon: Icons.edit_note,
          label: 'Tous',
          color: Colors.grey,
          onTap: () => _openAddEntry(),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ========================= DELEGATE DE RECHERCHE =========================
// (identique à l'original)
class JournalSearchDelegate extends SearchDelegate<String> {
  final JournalApiService _service;
  final int _userId;
  JournalSearchDelegate(this._service, this._userId);
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        if (query.isEmpty)
          close(context, '');
        else
          query = '';
      },
    ),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );
  @override
  Widget buildResults(BuildContext context) =>
      FutureBuilder<JournalEntriesPage>(
        future: _service.searchEntries(userId: _userId, keyword: query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Erreur: ${snapshot.error}'));
          final entries = snapshot.data?.entries ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Aucun résultat pour "$query"'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: Icon(
                  entry.entryType.icon,
                  color: entry.entryType.color,
                ),
                title: Text(entry.title ?? 'Sans titre'),
                subtitle: Text(
                  entry.content.length > 100
                      ? '${entry.content.substring(0, 100)}...'
                      : entry.content,
                ),
                trailing: Text(
                  DateFormat('dd/MM').format(entry.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JournalEntryDetailPage(entry: entry),
                    ),
                  );
                },
              );
            },
          );
        },
      );
  @override
  Widget buildSuggestions(BuildContext context) => Container();
}

// ========================= BOTTOM SHEET DE FILTRES =========================
// (identique à l'original)
class JournalFilterBottomSheet extends StatefulWidget {
  final Function(JournalFilter) onFilterApplied;
  const JournalFilterBottomSheet({super.key, required this.onFilterApplied});
  @override
  State<JournalFilterBottomSheet> createState() =>
      _JournalFilterBottomSheetState();
}

class _JournalFilterBottomSheetState extends State<JournalFilterBottomSheet> {
  EntryType? _selectedType;
  DateTimeRange? _dateRange;
  bool _showPrivateOnly = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrer les entrées',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTypeFilter(),
          const SizedBox(height: 20),
          _buildDateFilter(),
          const SizedBox(height: 20),
          _buildPrivacyFilter(),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _dateRange = null;
                      _showPrivateOnly = false;
                    });
                    widget.onFilterApplied(JournalFilter());
                  },
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFilterApplied(
                      JournalFilter(
                        entryType: _selectedType,
                        dateRange: _dateRange,
                        showPrivateOnly: _showPrivateOnly,
                      ),
                    );
                    Navigator.pop(context);
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

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type d\'entrée', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EntryType.values.map((type) {
            final isSelected = _selectedType == type;
            return FilterChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) =>
                  setState(() => _selectedType = selected ? type : null),
              avatar: Icon(type.icon, size: 16),
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

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Période', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: _dateRange,
            );
            if (picked != null) setState(() => _dateRange = picked);
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _dateRange == null
                ? 'Sélectionner une période'
                : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyFilter() {
    return Row(
      children: [
        Checkbox(
          value: _showPrivateOnly,
          onChanged: (value) =>
              setState(() => _showPrivateOnly = value ?? false),
        ),
        const SizedBox(width: 8),
        const Text('Privé uniquement'),
      ],
    );
  }
}

// ========================= MODÈLE DE FILTRE =========================
class JournalFilter {
  final EntryType? entryType;
  final DateTimeRange? dateRange;
  final bool showPrivateOnly;
  JournalFilter({this.entryType, this.dateRange, this.showPrivateOnly = false});
}
