/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge.dart';
import '../../widgets/challenge_status_badge.dart';
import '../../widgets/challenge_difficulty_indicator.dart';

class AdminChallengeListPage extends StatefulWidget {
  const AdminChallengeListPage({super.key});

  @override
  State<AdminChallengeListPage> createState() => _AdminChallengeListPageState();
}

class _AdminChallengeListPageState extends State<AdminChallengeListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedStatus;
  bool _isLoadingMore = false;

  final List<String> _statuses = [
    'DRAFT',
    'ACTIVE',
    'PAUSED',
    'COMPLETED',
    'ARCHIVED',
    'CANCELLED',
  ];

  final Map<String, String> _statusLabels = {
    'DRAFT': 'Brouillon',
    'ACTIVE': 'Actif',
    'PAUSED': 'En pause',
    'COMPLETED': 'Terminé',
    'ARCHIVED': 'Archivé',
    'CANCELLED': 'Annulé',
  };

  final Map<String, Color> _statusColors = {
    'DRAFT': Colors.grey,
    'ACTIVE': Colors.green,
    'PAUSED': Colors.orange,
    'COMPLETED': Colors.blue,
    'ARCHIVED': Colors.brown,
    'CANCELLED': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadChallenges();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadChallenges() async {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    await provider.loadChallenges(reset: true);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    await provider.loadMoreChallenges();

    setState(() => _isLoadingMore = false);
  }

  Future<void> _filterByStatus(String? status) async {
    setState(() {
      _selectedStatus = status;
    });

    if (status != null) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      // Implémenter la méthode pour filtrer par statut
      // await provider.getChallengesByStatus(status);
    } else {
      await _loadChallenges();
    }
  }

  Future<void> _toggleChallengeStatus(Challenge challenge) async {
    final newStatus = challenge.status == 'ACTIVE' ? false : true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newStatus ? 'Activer le défi ?' : 'Désactiver le défi ?'),
        content: Text(
          newStatus
              ? 'Le défi sera visible par tous les utilisateurs.'
              : 'Le défi ne sera plus visible par les utilisateurs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus ? 'Activer' : 'Désactiver'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      await provider.toggleChallengeStatus(challenge.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? '✅ Défi activé avec succès' : '⏸️ Défi désactivé',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteChallenge(Challenge challenge) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le défi ?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${challenge.title}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      final success = await provider.deleteChallenge(challenge.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Défi supprimé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Gestion des défis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              context.push('/admin/challenges/add');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un défi...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF7DBBC3),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    // Implémenter la recherche
                  },
                ),
                const SizedBox(height: 12),

                // Filtres par statut
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildFilterChip(
                          label: 'Tous',
                          isSelected: _selectedStatus == null,
                          onTap: () => _filterByStatus(null),
                        );
                      }
                      final status = _statuses[index - 1];
                      return _buildFilterChip(
                        label: _statusLabels[status]!,
                        isSelected: _selectedStatus == status,
                        onTap: () => _filterByStatus(status),
                        color: _statusColors[status],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des défis
          Expanded(
            child: Consumer<ChallengeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.challenges.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.challenges.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun défi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par créer un nouveau défi',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.push('/admin/challenges/add');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7DBBC3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Créer un défi'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      provider.challenges.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.challenges.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final challenge = provider.challenges[index];
                    return _buildChallengeCard(challenge);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: (color ?? const Color(0xFF7DBBC3)).withOpacity(0.2),
        checkmarkColor: color ?? const Color(0xFF7DBBC3),
        labelStyle: TextStyle(
          color: isSelected
              ? (color ?? const Color(0xFF7DBBC3))
              : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected
              ? (color ?? const Color(0xFF7DBBC3))
              : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7DBBC3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Color(0xFF7DBBC3),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                challenge.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ChallengeStatusBadge(status: challenge.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              ChallengeDifficultyIndicator(
                difficulty: challenge.difficultyLevel,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${challenge.id} • ${challenge.currentParticipants} participants',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistiques
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.people,
                      value: '${challenge.currentParticipants}',
                      label: 'Participants',
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      icon: Icons.emoji_events,
                      value: '${challenge.pointsReward ?? 0}',
                      label: 'Points',
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      icon: Icons.star,
                      value: '${challenge.xpReward ?? 0}',
                      label: 'XP',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Dates
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Créé le: ${_formatDate(challenge.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push('/admin/challenges/${challenge.id}/edit');
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7DBBC3),
                        side: const BorderSide(color: Color(0xFF7DBBC3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _toggleChallengeStatus(challenge),
                      icon: Icon(
                        challenge.status == 'ACTIVE'
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(
                        challenge.status == 'ACTIVE' ? 'Pause' : 'Activer',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: challenge.status == 'ACTIVE'
                            ? Colors.orange
                            : Colors.green,
                        side: BorderSide(
                          color: challenge.status == 'ACTIVE'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _deleteChallenge(challenge),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7DBBC3)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}*/
