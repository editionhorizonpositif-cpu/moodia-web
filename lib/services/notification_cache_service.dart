import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationCacheService {
  static const String _cachedNotificationsKey = 'cached_notifications';
  static const String _pendingReadIdsKey = 'pending_read_ids';

  // Sauvegarder la liste complète des notifications
  static Future<void> saveNotifications(
    List<NotificationModel> notifications,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_cachedNotificationsKey, jsonEncode(jsonList));
      if (kDebugMode)
        print('💾 ${notifications.length} notifications sauvegardées en cache');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde cache notifications: $e');
    }
  }

  // Charger les notifications depuis le cache
  static Future<List<NotificationModel>> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedNotificationsKey);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final notifications = jsonList
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      if (kDebugMode)
        print(
          '📦 ${notifications.length} notifications chargées depuis le cache',
        );
      return notifications;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cache notifications: $e');
      return [];
    }
  }

  // Ajouter un ID de notification à la liste des lectures en attente
  static Future<void> addPendingReadId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingIds = prefs.getStringList(_pendingReadIdsKey) ?? [];
      if (!pendingIds.contains(id.toString())) {
        pendingIds.add(id.toString());
        await prefs.setStringList(_pendingReadIdsKey, pendingIds);
        if (kDebugMode) print('⏳ Lecture en attente ajoutée: $id');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur ajout pending read: $e');
    }
  }

  // Récupérer les IDs en attente
  static Future<List<int>> getPendingReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingStrings = prefs.getStringList(_pendingReadIdsKey) ?? [];
      return pendingStrings
          .map((s) => int.tryParse(s) ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Supprimer un ID de la liste (après synchronisation réussie)
  static Future<void> removePendingReadId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingIds = prefs.getStringList(_pendingReadIdsKey) ?? [];
      pendingIds.remove(id.toString());
      await prefs.setStringList(_pendingReadIdsKey, pendingIds);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur suppression pending read: $e');
    }
  }

  // Vider la liste des lectures en attente (après synchro globale)
  static Future<void> clearPendingReads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingReadIdsKey);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur effacement pending reads: $e');
    }
  }
}
