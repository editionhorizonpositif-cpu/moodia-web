// lib/pages/notifications_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_api_service.dart';
import '../models/notification.dart';
import '../widgets/empty_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final NotificationApiService _notificationService = NotificationApiService();
  late TabController _tabController;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> _unreadNotifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  bool _hasMore = true;
  String _searchQuery = '';
  bool _isSearching = false;

  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  final ScrollController _scrollController = ScrollController();
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  int? _userId; // <-- Ajout de l'ID utilisateur

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initConnectivity();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // ========== CONNECTIVITÉ ==========
  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateOnlineStatus(result);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateOnlineStatus,
    );
  }

  void _updateOnlineStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
    if (!wasOnline && _isOnline) {
      _syncPendingReads();
    }
  }

  Future<void> _syncPendingReads() async {
    await _notificationService.syncPendingReads();
    await _loadInitialData();
  }

  // ========== CHARGEMENT DE L'ID UTILISATEUR ==========
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    if (kDebugMode) print('👤 UserId chargé : $_userId');
  }

  // ========== CHARGEMENT DES DONNÉES ==========
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _loadUserId(); // Attendre l'ID utilisateur
      if (_userId == null) {
        throw Exception('Utilisateur non connecté');
      }
      await _loadNotifications(reset: true);
      await _loadUnreadNotifications();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement initial: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
      });
    }

    try {
      final notifications = await _notificationService
          .loadNotificationsWithCache(
            page: _currentPage,
            size: 20,
            forceRefresh: reset && _isOnline,
          );

      setState(() {
        if (reset) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _hasMore = notifications.length >= 20 && _isOnline;
        if (_hasMore && reset) _currentPage++;
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _loadNotifications: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final unread = _notifications.where((n) => !n.seen).toList();
      setState(() => _unreadNotifications = unread);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement non lues: $e');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isSearching &&
        _isOnline) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    await _loadNotifications();
    setState(() => _isLoadingMore = false);
  }

  // ========== GESTION DES LECTURES ==========
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.seen) return;

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(
          seen: true,
          readAt: DateTime.now(),
        );
      }
      _unreadNotifications.removeWhere((n) => n.id == notification.id);
    });

    await _notificationService.markAsReadWithCache(notification.id);

    if (_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marquée comme lue'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadIds = _unreadNotifications.map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].seen) {
          _notifications[i] = _notifications[i].copyWith(
            seen: true,
            readAt: DateTime.now(),
          );
        }
      }
      _unreadNotifications.clear();
    });

    for (var id in unreadIds) {
      await _notificationService.markAsReadWithCache(id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications marquées comme lues'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ========== SUPPRESSION ==========
  Future<void> _deleteNotification(int id) async {
    try {
      final success = await _notificationService.deleteNotification(id);
      if (success) {
        setState(() {
          _notifications.removeWhere((n) => n.id == id);
          _unreadNotifications.removeWhere((n) => n.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer toutes vos notifications ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final success = await _notificationService.deleteAllMyNotifications();
      if (success) {
        setState(() {
          _notifications.clear();
          _unreadNotifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications supprimées'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ========== RECHERCHE ==========
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _isSearching = value.isNotEmpty;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      await _loadNotifications(reset: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _notificationService.searchMyNotifications(
        _searchQuery,
      );
      setState(() {
        _notifications = results;
        _hasMore = false;
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erreur recherche: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    FocusScope.of(context).unfocus();
    _loadNotifications(reset: true);
  }

  // ========== FILTRES ==========
  List<NotificationModel> get _filteredNotifications {
    List<NotificationModel> filtered = _notifications;
    if (_selectedFilter != 'all') {
      filtered = filtered.where((n) {
        switch (_selectedFilter) {
          case 'unread':
            return !n.seen;
          case 'system':
            return n.type.toLowerCase() == 'system';
          case 'reminder':
            return n.type.toLowerCase() == 'reminder';
          case 'achievement':
            return n.type.toLowerCase() == 'achievement';
          default:
            return true;
        }
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (n) =>
                n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                n.message.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return filtered;
  }

  // ========== WIDGETS ==========
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.deepPurple[50],
      checkmarkColor: Colors.deepPurple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }

  void _showNotificationDetail(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              notification.typeIcon,
              color: notification.priorityColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.message,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    notification.formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (notification.type.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.label, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      notification.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: notification.priorityColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (notification.message.length > 100)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFullScreenMessage(notification);
              },
              child: const Text('Voir tout'),
            ),
        ],
      ),
    );
  }

  void _showFullScreenMessage(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    notification.message,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: notification.seen ? Colors.white : Colors.deepPurple.shade50,
      child: InkWell(
        onTap: () {
          _showNotificationDetail(notification);
          if (!notification.seen) _markAsRead(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.priorityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.typeIcon,
                  color: notification.priorityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.seen
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.timeAgo,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (!notification.seen)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _deleteNotification(notification.id),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Iconsax.tick_circle),
              tooltip: 'Tout marquer comme lu',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_all') _deleteAllNotifications();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Iconsax.trash, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Supprimer tout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Iconsax.more),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Iconsax.close_circle),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.deepPurple,
                  tabs: const [
                    Tab(text: 'Toutes'),
                    Tab(text: 'Non lues'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Toutes', 'all', Iconsax.notification),
                  const SizedBox(width: 8),
                  _buildFilterChip('Non lues', 'unread', Iconsax.eye_slash),
                  const SizedBox(width: 8),
                  _buildFilterChip('Système', 'system', Iconsax.setting),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rappels', 'reminder', Iconsax.clock),
                  const SizedBox(width: 8),
                  _buildFilterChip('Succès', 'achievement', Iconsax.award),
                ],
              ),
            ),
          ),
          if (!_isOnline)
            Container(
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Mode hors ligne - Les modifications seront synchronisées plus tard',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotificationsTab(),
                _buildUnreadNotificationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab() {
    if (_isLoading && _notifications.isEmpty) return _buildLoadingShimmer();

    final filtered = _filteredNotifications;
    if (filtered.isEmpty) {
      return EmptyState(
        icon: Iconsax.notification,
        title: _searchQuery.isEmpty ? 'Aucune notification' : 'Aucun résultat',
        message: _searchQuery.isEmpty
            ? 'Vous n\'avez pas encore reçu de notifications'
            : 'Aucune notification ne correspond à votre recherche',
        actionText: _searchQuery.isEmpty ? 'Actualiser' : 'Effacer',
        onAction: _searchQuery.isEmpty ? _loadInitialData : _clearSearch,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: Colors.deepPurple,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < filtered.length) {
            return _buildNotificationCard(filtered[index]);
          } else {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
        },
      ),
    );
  }

  Widget _buildUnreadNotificationsTab() {
    if (_isLoading && _unreadNotifications.isEmpty)
      return _buildLoadingShimmer();
    if (_unreadNotifications.isEmpty) {
      return EmptyState(
        icon: Iconsax.eye,
        title: 'Tout est lu !',
        message: 'Vous n\'avez aucune notification non lue',
        actionText: 'Actualiser',
        onAction: _loadInitialData,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unreadNotifications.length,
        itemBuilder: (context, index) =>
            _buildNotificationCard(_unreadNotifications[index]),
      ),
    );
  }
}
