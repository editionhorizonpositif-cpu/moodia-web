/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Pour HapticFeedback
import '../../providers/challenge_provider.dart';
import '../../services/auth_service.dart';
import '../../models/challenge_completion.dart';
import '../../routes/route.dart';

class UserChallengeHistoryPage extends StatefulWidget {
  const UserChallengeHistoryPage({super.key});

  @override
  State<UserChallengeHistoryPage> createState() =>
      _UserChallengeHistoryPageState();
}

class _UserChallengeHistoryPageState extends State<UserChallengeHistoryPage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<ChallengeCompletion> _completions = [];
  String _selectedFilter = 'tous';
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _filters = ['tous', 'parfaits', 'récents', 'mieux notés'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHistory();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadHistory() async {
    final userId = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser?.id;

    if (userId != null) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      await provider.loadUserCompletions(userId);

      if (mounted) {
        setState(() {
          _completions = provider.userCompletions;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshHistory() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);

    final userId = Provider.of<AuthService>(
      context,
      listen: false,
    ).currentUser?.id;

    if (userId != null) {
      final provider = Provider.of<ChallengeProvider>(context, listen: false);
      await provider.loadUserCompletions(userId);

      if (mounted) {
        setState(() {
          _completions = provider.userCompletions;
          _isRefreshing = false;
        });
      }
    }
  }

  List<ChallengeCompletion> _getFilteredCompletions() {
    // D'abord filtrer par recherche
    var filtered = _completions.where((completion) {
      return completion.challengeTitle.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    // Ensuite appliquer les filtres
    switch (_selectedFilter) {
      case 'parfaits':
        return filtered.where((c) => c.isPerfectCompletion ?? false).toList();
      case 'récents':
        filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        return filtered;
      case 'mieux notés':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        return filtered;
      default:
        return filtered;
    }
  }

  void _navigateToHome() {
    // Navigation 2.0 - pushNamedAndRemoveUntil pour revenir à l'accueil
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Quitter l\'historique ?'),
        content: const Text('Voulez-vous retourner à l\'accueil ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToHome();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DBBC3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _navigateToChallengeSearch() {
    HapticFeedback.lightImpact();
    // Navigation 2.0 - pushNamed
    Navigator.pushNamed(context, AppRoutes.challengeSearch);
  }

  void _navigateToChallengeDetail(int challengeId) {
    // Navigation 2.0 avec argument
    Navigator.pushNamed(
      context,
      '/challenges/$challengeId',
      arguments: challengeId,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF2C3E50),
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context), // Navigation 2.0 - pop
        ),
        actions: [
          // Bouton home
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Color(0xFF2C3E50),
                size: 20,
              ),
            ),
            onPressed: _showExitDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            210,
          ), // Augmenté pour éviter overflow
          child: Column(
            children: [
              // Titre et stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Si l'écran est trop petit, on empile verticalement
                    if (constraints.maxWidth < 400) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mon historique',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amber.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_completions.length} défis',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Version normale avec Row
                    return Row(
                      children: [
                        const Text(
                          'Mon historique',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_completions.length} défis',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Barre de recherche
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un défi...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF7DBBC3),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Filtres horizontaux
              Container(
                height: 50,
                margin: const EdgeInsets.only(left: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF7DBBC3),
                                    Color(0xFF5A9AA3),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(25),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            filter[0].toUpperCase() + filter.substring(1),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7DBBC3).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading
                  ? _buildLoadingState()
                  : _completions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshHistory,
                      color: const Color(0xFF7DBBC3),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _getFilteredCompletions().length,
                        itemBuilder: (context, index) {
                          final completion = _getFilteredCompletions()[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildHistoryCard(completion, index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          // Indicateur de rafraîchissement
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFF7DBBC3).withOpacity(0.9),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Rafraîchissement...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7DBBC3), Color(0xFF5A9AA3)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chargement de votre historique...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Retrouvez tous vos défis accomplis',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation container
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF7DBBC3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 80,
                color: Color(0xFF7DBBC3),
              ),
            ),

            const SizedBox(height: 24),

            // Message principal
            const Text(
              'Aucun historique',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),

            const SizedBox(height: 8),

            // Message secondaire
            Text(
              'Les défis que vous compléterez apparaîtront ici\navec toutes vos statistiques',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _refreshHistory,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Actualiser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7DBBC3),
                      side: const BorderSide(color: Color(0xFF7DBBC3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToChallengeSearch,
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Explorer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7DBBC3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton retour accueil
            TextButton.icon(
              onPressed: _navigateToHome,
              icon: const Icon(Icons.home_outlined, color: Color(0xFF7DBBC3)),
              label: const Text(
                'Retour à l\'accueil',
                style: TextStyle(
                  color: Color(0xFF7DBBC3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ChallengeCompletion completion, int index) {
    final date = DateTime.parse(completion.completedAt.toIso8601String());
    final isPerfect = completion.isPerfectCompletion ?? false;
    final rating = completion.rating ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          if (isPerfect)
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToChallengeDetail(completion.challengeId);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec badge parfait
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône du défi
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPerfect
                              ? [Colors.amber, Colors.orange]
                              : [
                                  const Color(0xFF7DBBC3),
                                  const Color(0xFF5A9AA3),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isPerfect
                                        ? Colors.amber
                                        : const Color(0xFF7DBBC3))
                                    .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPerfect
                            ? Icons.stars_rounded
                            : Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Titre et date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completion.challengeTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd MMMM yyyy').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Badge parfait
                    if (isPerfect)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Parfait',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Si l'écran est trop petit, on réduit l'espacement
                      if (constraints.maxWidth < 350) {
                        return Wrap(
                          alignment: WrapAlignment.spaceAround,
                          runSpacing: 16,
                          children: [
                            _buildStatItem(
                              icon: Icons.star_rounded,
                              value: rating.toStringAsFixed(1),
                              label: 'Note',
                              color: Colors.amber,
                              suffix: '/5',
                            ),
                            _buildStatItem(
                              icon: Icons.timer_rounded,
                              value: '${completion.completionTimeDays ?? 0}',
                              label: 'Durée',
                              color: const Color(0xFF7DBBC3),
                              suffix: 'j',
                            ),
                            _buildStatItem(
                              icon: Icons.local_fire_department_rounded,
                              value: '${completion.finalStreakDays ?? 0}',
                              label: 'Streak',
                              color: Colors.orange,
                              suffix: '',
                            ),
                            _buildStatItem(
                              icon: Icons.emoji_events_rounded,
                              value: '${completion.pointsEarned ?? 0}',
                              label: 'Points',
                              color: Colors.purple,
                              suffix: '',
                            ),
                          ],
                        );
                      }

                      // Version normale avec Row
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: Icons.star_rounded,
                            value: rating.toStringAsFixed(1),
                            label: 'Note',
                            color: Colors.amber,
                            suffix: '/5',
                          ),
                          _buildStatItem(
                            icon: Icons.timer_rounded,
                            value: '${completion.completionTimeDays ?? 0}',
                            label: 'Durée',
                            color: const Color(0xFF7DBBC3),
                            suffix: 'j',
                          ),
                          _buildStatItem(
                            icon: Icons.local_fire_department_rounded,
                            value: '${completion.finalStreakDays ?? 0}',
                            label: 'Streak',
                            color: Colors.orange,
                            suffix: '',
                          ),
                          _buildStatItem(
                            icon: Icons.emoji_events_rounded,
                            value: '${completion.pointsEarned ?? 0}',
                            label: 'Points',
                            color: Colors.purple,
                            suffix: '',
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Feedback si présent
                if (completion.feedback != null &&
                    completion.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DBBC3).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF7DBBC3).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 20,
                          color: Color(0xFF7DBBC3),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            completion.feedback!,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Indice de progression dans la liste
                if (index < 3)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.amber
                                : index == 1
                                ? Colors.grey
                                : Colors.brown,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String suffix,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            if (suffix.isNotEmpty)
              Text(
                suffix,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}*/
