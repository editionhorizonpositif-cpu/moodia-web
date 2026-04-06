// lib/pages/journal_entry_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moodia/models/journal_entry.dart';
import 'package:moodia/services/journal_api_service.dart';
import 'package:moodia/pages/add_edit_journal_page.dart';

class JournalEntryDetailPage extends StatefulWidget {
  final JournalEntry entry;

  const JournalEntryDetailPage({super.key, required this.entry});

  @override
  State<JournalEntryDetailPage> createState() => _JournalEntryDetailPageState();
}

class _JournalEntryDetailPageState extends State<JournalEntryDetailPage> {
  final JournalApiService _journalService = JournalApiService();
  late JournalEntry _entry;
  bool _isLoading = false;
  bool _isOnline = true;
  String? _connectionStatus;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _initConnectivity();
    _refreshEntryIfNeeded(); // recharge en ligne si disponible
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // === GESTION DE LA CONNECTIVITÉ ===
  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(result);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  void _updateConnectivityStatus(ConnectivityResult result) {
    setState(() {
      _isOnline = result != ConnectivityResult.none;
      _connectionStatus = _isOnline ? '📶 En ligne' : '📴 Mode hors-ligne';
    });
    // Si on revient en ligne, on peut recharger discrètement
    if (_isOnline) {
      _refreshEntrySilently();
    }
  }

  // Recharge l'entrée sans afficher de loader, pour mettre à jour les données en arrière-plan
  Future<void> _refreshEntrySilently() async {
    try {
      final fresh = await _journalService.getEntryById(
        _entry.id!,
        _entry.userId!,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _entry = fresh;
        });
      }
    } catch (e) {
      // Échec silencieux, pas de notification
    }
  }

  // Recharge avec indicateur de chargement
  Future<void> _refreshEntry() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’actualiser : mode hors ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final fresh = await _journalService.getEntryById(
        _entry.id!,
        _entry.userId!,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _entry = fresh;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrée actualisée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Si l’entrée est passée depuis une liste déjà à jour, on ne recharge pas forcément,
  // mais on le fait si on est en ligne pour être sûr d’avoir la dernière version.
  Future<void> _refreshEntryIfNeeded() async {
    if (_isOnline) {
      await _refreshEntrySilently();
    }
  }

  // === ACTIONS ===
  Future<void> _editEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditJournalPage(entry: _entry, isEditing: true),
      ),
    );
    if (result == true && mounted) {
      // Recharger l’entrée après modification
      await _refreshEntrySilently();
    }
  }

  Future<void> _deleteEntry() async {
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
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _journalService.deleteEntry(_entry.id!, _entry.userId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrée supprimée'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // retour avec succès pour rafraîchir la liste
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _shareEntry() {
    // À implémenter si besoin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage à venir'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final primaryColor = _entry.entryType.color;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFFAF8F5),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // AppBar avec indicateur de connexion
                SliverAppBar(
                  expandedHeight: 320,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: _buildFlexibleSpace(primaryColor),
                  leading: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    // Indicateur de connexion
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      onPressed: _refreshEntry,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Actualiser',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) {
                        if (value == 'edit') _editEntry();
                        if (value == 'delete') _deleteEntry();
                        if (value == 'share') _shareEntry();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Modifier'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Partager'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Contenu principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(_entry.createdAt, colorScheme),
                        const SizedBox(height: 32),

                        if (_entry.title?.isNotEmpty ?? false) ...[
                          _buildTitleSection(primaryColor),
                          const SizedBox(height: 32),
                        ],

                        _buildJournalContent(
                          _entry.content,
                          isDark,
                          colorScheme,
                          primaryColor,
                        ),
                        const SizedBox(height: 40),

                        if (_entry.tags.isNotEmpty) ...[
                          _buildSectionTitle(
                            title: 'Mots-clés',
                            icon: Icons.tag_faces_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 20),
                          _buildTagsSection(_entry.tags),
                          const SizedBox(height: 40),
                        ],

                        _buildSectionTitle(
                          title: 'Statistiques',
                          icon: Icons.analytics_rounded,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 20),
                        _buildStatisticsGrid(_entry),

                        const SizedBox(height: 40),
                        _buildActionButtons(colorScheme),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFlexibleSpace(Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final currentHeight = constraints.biggest.height;
        final opacity = (currentHeight - 120) / (maxHeight - 120);

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroBackground(primaryColor, context),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.6),
                    primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: opacity.clamp(0.0, 1.0),
                duration: Duration.zero,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: opacity.clamp(0.0, 1.0),
                duration: Duration.zero,
                child: _buildHeroContent(primaryColor),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: (1 - opacity).clamp(0.0, 1.0),
                duration: Duration.zero,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _entry.entryType.icon,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _entry.entryType.displayName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroBackground(Color primaryColor, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        for (int i = 0; i < 5; i++)
          Positioned(
            left: i % 2 == 0 ? 20 + i * 50 : screenWidth - 100 - i * 50,
            top: 50 + i * 40,
            child: Container(
              width: 80 + i * 20,
              height: 80 + i * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(0.15 - i * 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: 100,
          right: -50,
          child: Transform.rotate(
            angle: 0.5,
            child: Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroContent(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.2),
            primaryColor.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_entry.moodRating != null)
                  _buildHeroMetric(
                    icon: _getMoodIcon(_entry.moodRating!),
                    value: '${_entry.moodRating!}/10',
                    label: 'Humeur',
                    color: _getMoodColor(_entry.moodRating!),
                  ),
                if (_entry.wordCount != null)
                  _buildHeroMetric(
                    icon: Icons.text_fields_rounded,
                    value: '${_entry.wordCount!}',
                    label: 'Mots',
                    color: Colors.white,
                  ),
                _buildHeroMetric(
                  icon: Icons.access_time_filled_rounded,
                  value: DateFormat('HH:mm').format(_entry.createdAt),
                  label: 'Heure',
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.15),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE', 'fr_FR').format(date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('d MMMM y', 'fr_FR').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_entry.isPrivate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.2),
                    Colors.deepPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Colors.deepPurple),
                  const SizedBox(width: 6),
                  Text(
                    'Privé',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            primaryColor.withOpacity(0.15),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.format_quote_rounded, color: primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _entry.title!,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalContent(
    String content,
    bool isDark,
    ColorScheme colorScheme,
    Color primaryColor,
  ) {
    final words = content.split(' ').length;
    final readingTime = _calculateReadTime(content);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : const Color(0xFFEAE6E1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border(
                bottom: BorderSide(
                  color: primaryColor.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.2),
                        primaryColor.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votre réflexion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$words mots • $readingTime',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.2),
                            primaryColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          content[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            fontFamily: 'Georgia',
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.8,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.grey[200]
                          : const Color(0xFF444444),
                      fontFamily: 'Merriweather',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(Set<String> tags) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.25),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle_rounded, size: 10, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                '#$tag',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatisticsGrid(JournalEntry entry) {
    final stats = [
      {
        'icon': Icons.text_fields_rounded,
        'value': '${entry.wordCount ?? 0}',
        'label': 'Mots',
        'color': Colors.blue,
      },
      {
        'icon': Icons.timer_rounded,
        'value': _calculateReadTime(entry.content),
        'label': 'Lecture',
        'color': Colors.green,
      },
      {
        'icon': Icons.edit_calendar_rounded,
        'value': DateFormat('dd/MM').format(entry.createdAt),
        'label': 'Créée',
        'color': Colors.orange,
      },
      {
        'icon': Icons.update_rounded,
        'value': DateFormat('dd/MM').format(entry.updatedAt),
        'label': 'Modifiée',
        'color': Colors.purple,
      },
      {
        'icon': Icons.speed_rounded,
        'value': '${_calculateReadingSpeed(entry.content)}',
        'label': 'Mots/min',
        'color': Colors.red,
      },
      {
        'icon': Icons.psychology_rounded,
        'value': entry.moodRating != null ? '${entry.moodRating}/10' : '-',
        'label': 'Humeur',
        'color': Colors.cyan,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return _buildStatCard(
          icon: stat['icon'] as IconData,
          value: stat['value'] as String,
          label: stat['label'] as String,
          color: color,
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editEntry,
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: const Text(
                'Modifier',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareEntry,
              icon: const Icon(Icons.share_rounded, size: 20),
              label: const Text(
                'Partager',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== UTILITAIRES ==========
  IconData _getMoodIcon(int rating) {
    if (rating >= 8) return Icons.sentiment_very_satisfied_rounded;
    if (rating >= 6) return Icons.sentiment_satisfied_rounded;
    if (rating >= 4) return Icons.sentiment_neutral_rounded;
    if (rating >= 2) return Icons.sentiment_dissatisfied_rounded;
    return Icons.sentiment_very_dissatisfied_rounded;
  }

  Color _getMoodColor(int rating) {
    if (rating >= 8) return const Color(0xFF4CAF50);
    if (rating >= 6) return const Color(0xFF8BC34A);
    if (rating >= 4) return const Color(0xFFFF9800);
    if (rating >= 2) return const Color(0xFFFF5722);
    return const Color(0xFFF44336);
  }

  String _calculateReadTime(String content) {
    if (content.trim().isEmpty) return '0 min';
    final words = content.trim().split(RegExp(r'\s+')).length;
    final readingSpeed = 225; // mots par minute
    final minutes = (words / readingSpeed).ceil();
    if (minutes == 0) {
      final seconds = (words / readingSpeed * 60).ceil();
      return '$seconds sec';
    } else if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0
          ? '$hours h $remainingMinutes min'
          : '$hours h';
    }
  }

  int _calculateReadingSpeed(String content) {
    if (content.trim().isEmpty) return 0;
    final words = content.trim().split(RegExp(r'\s+')).length;
    final readingTimeMinutes = words / 225; // 225 mots par minute
    return (words / readingTimeMinutes).round();
  }
}
