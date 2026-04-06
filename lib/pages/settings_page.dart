// lib/pages/settings_page.dart - Version opérationnelle avec messages pour actions non implémentées

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Paramètres d'affichage
  bool _darkMode = false;
  bool _reduceAnimations = false;
  bool _highContrast = false;
  double _fontSize = 1.0; // 1.0 = taille normale
  String _themeColor = 'Bleu';

  // Paramètres de confidentialité
  bool _analyticsEnabled = true;
  bool _personalizedAds = false;
  bool _dataSharing = false;
  bool _showOnlineStatus = true;

  // Paramètres de compte
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  String _notificationFrequency = 'Réel';

  // Paramètres avancés
  bool _autoUpdate = true;
  bool _backgroundSync = true;
  bool _cacheEnabled = true;
  String _videoQuality = 'Auto';
  String _downloadQuality = 'Haute';

  // Langue et région
  String _selectedLanguage = 'Français';
  String _selectedRegion = 'France';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '24h';
  String _temperatureUnit = 'Celsius';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _reduceAnimations = prefs.getBool('reduce_animations') ?? false;
        _highContrast = prefs.getBool('high_contrast') ?? false;
        _fontSize = prefs.getDouble('font_size') ?? 1.0;
        _themeColor = prefs.getString('theme_color') ?? 'Bleu';

        _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
        _personalizedAds = prefs.getBool('personalized_ads') ?? false;
        _dataSharing = prefs.getBool('data_sharing') ?? false;
        _showOnlineStatus = prefs.getBool('show_online_status') ?? true;

        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _smsNotifications = prefs.getBool('sms_notifications') ?? false;
        _notificationFrequency =
            prefs.getString('notification_frequency') ?? 'Réel';

        _autoUpdate = prefs.getBool('auto_update') ?? true;
        _backgroundSync = prefs.getBool('background_sync') ?? true;
        _cacheEnabled = prefs.getBool('cache_enabled') ?? true;
        _videoQuality = prefs.getString('video_quality') ?? 'Auto';
        _downloadQuality = prefs.getString('download_quality') ?? 'Haute';

        _selectedLanguage = prefs.getString('language') ?? 'Français';
        _selectedRegion = prefs.getString('region') ?? 'France';
        _dateFormat = prefs.getString('date_format') ?? 'DD/MM/YYYY';
        _timeFormat = prefs.getString('time_format') ?? '24h';
        _temperatureUnit = prefs.getString('temperature_unit') ?? 'Celsius';
      });
    } catch (e) {
      debugPrint('Erreur chargement préférences: $e');
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde préférence $key: $e');
    }
  }

  void _showNotImplementedSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature non disponible pour l\'instant'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Réinitialiser les paramètres',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser tous les paramètres aux valeurs par défaut ?',
          style: TextStyle(color: Color(0xFF5D6D7E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFF7DBBC3)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _resetToDefaults();
              Navigator.pop(context);
              _showSuccessSnackbar('Paramètres réinitialisés avec succès');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    // Réinitialiser toutes les préférences
    await prefs.clear();

    setState(() {
      _darkMode = false;
      _reduceAnimations = false;
      _highContrast = false;
      _fontSize = 1.0;
      _themeColor = 'Bleu';

      _analyticsEnabled = true;
      _personalizedAds = false;
      _dataSharing = false;
      _showOnlineStatus = true;

      _emailNotifications = true;
      _pushNotifications = true;
      _smsNotifications = false;
      _notificationFrequency = 'Réel';

      _autoUpdate = true;
      _backgroundSync = true;
      _cacheEnabled = true;
      _videoQuality = 'Auto';
      _downloadQuality = 'Haute';

      _selectedLanguage = 'Français';
      _selectedRegion = 'France';
      _dateFormat = 'DD/MM/YYYY';
      _timeFormat = '24h';
      _temperatureUnit = 'Celsius';
    });
  }

  void _exportSettings() {
    _showNotImplementedSnackbar('Export des paramètres');
  }

  void _importSettings() {
    _showNotImplementedSnackbar('Import des paramètres');
  }

  Future<void> _launchPrivacyPolicy() async {
    final url = Uri.parse('https://moodia.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showNotImplementedSnackbar(
        'Ouverture de la politique de confidentialité',
      );
    }
  }

  Future<void> _launchTermsOfService() async {
    final url = Uri.parse('https://moodia.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showNotImplementedSnackbar('Ouverture des conditions d\'utilisation');
    }
  }

  void _showHelpDialog() {
    _showNotImplementedSnackbar('Centre d\'aide');
  }

  Future<void> _showLanguageSelector() async {
    _showNotImplementedSnackbar('Sélection de la langue');
  }

  Future<void> _showRegionSelector() async {
    _showNotImplementedSnackbar('Sélection de la région');
  }

  Future<void> _toggleTwoFactorAuth() async {
    _showNotImplementedSnackbar('Authentification à deux facteurs');
  }

  Future<void> _showChangePasswordDialog() async {
    _showNotImplementedSnackbar('Changement de mot de passe');
  }

  Future<void> _showEditProfileDialog() async {
    _showNotImplementedSnackbar('Édition du profil');
  }

  // ... les méthodes de construction de l'UI restent identiques
  // (je ne les recopie pas pour alléger la réponse, mais elles sont inchangées)

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonne gauche : Navigation
          Expanded(flex: 2, child: _buildNavigationRail()),

          const SizedBox(width: 32),

          // Colonne droite : Contenu
          Expanded(flex: 5, child: _buildSettingsContent()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres'),
          bottom: TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.palette), text: 'Apparence'),
              Tab(icon: Icon(Icons.security), text: 'Confidentialité'),
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              Tab(icon: Icon(Icons.language), text: 'Langue'),
            ],
            labelColor: const Color(0xFF7DBBC3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF7DBBC3),
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppearanceSettings(),
            _buildPrivacySettings(),
            _buildNotificationSettings(),
            _buildLanguageSettings(),
          ],
        ),
        bottomNavigationBar: _buildBottomActions(),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'OpenSans',
                ),
              ),
            ),

            _buildNavItem(
              icon: Icons.palette,
              title: 'Apparence',
              subtitle: 'Thème, couleurs, taille de police',
              isActive: true,
            ),

            const SizedBox(height: 16),

            _buildNavItem(
              icon: Icons.security,
              title: 'Confidentialité',
              subtitle: 'Données, sécurité, permissions',
            ),

            const SizedBox(height: 16),

            _buildNavItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Alertes, sons, fréquences',
            ),

            const SizedBox(height: 16),

            _buildNavItem(
              icon: Icons.language,
              title: 'Langue & Région',
              subtitle: 'Langue, format de date, unités',
            ),

            const SizedBox(height: 16),

            _buildNavItem(
              icon: Icons.storage,
              title: 'Stockage & Données',
              subtitle: 'Cache, qualité, synchronisation',
            ),

            const SizedBox(height: 16),

            _buildNavItem(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              subtitle: 'FAQ, contact, assistance',
            ),

            const Spacer(),

            _buildSystemInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isActive = false,
  }) {
    return Material(
      color: isActive
          ? const Color(0xFF7DBBC3).withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF7DBBC3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF7DBBC3) : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(0xFF7DBBC3)
                            : const Color(0xFF2C3E50),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive
                            ? const Color(0xFF7DBBC3).withOpacity(0.8)
                            : const Color(0xFF7F8C8D),
                        fontFamily: 'OpenSans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (isActive)
                const Icon(Icons.chevron_right, color: Color(0xFF7DBBC3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Apparence',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),
          ),

          // Cartes de paramètres
          _buildAppearanceSettings(),
          const SizedBox(height: 24),
          _buildPrivacySettings(),
          const SizedBox(height: 24),
          _buildNotificationSettings(),
          const SizedBox(height: 24),
          _buildLanguageSettings(),
          const SizedBox(height: 24),
          _buildStorageSettings(),
          const SizedBox(height: 24),
          _buildAboutSection(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apparence',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),

            const SizedBox(height: 20),

            // Thème
            _buildSettingSwitchRow(
              icon: Icons.brightness_6,
              title: 'Mode sombre',
              subtitle: 'Activer le thème sombre',
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                _savePreference('dark_mode', value);
                _showSuccessSnackbar(
                  value ? 'Mode sombre activé' : 'Mode sombre désactivé',
                );
              },
            ),

            const SizedBox(height: 16),

            // Réduire les animations
            _buildSettingSwitchRow(
              icon: Icons.animation,
              title: 'Réduire les animations',
              subtitle: 'Désactiver les animations pour plus de fluidité',
              value: _reduceAnimations,
              onChanged: (value) {
                setState(() => _reduceAnimations = value);
                _savePreference('reduce_animations', value);
              },
            ),

            const SizedBox(height: 16),

            // Contraste élevé
            _buildSettingSwitchRow(
              icon: Icons.contrast,
              title: 'Contraste élevé',
              subtitle: 'Améliorer la visibilité du texte',
              value: _highContrast,
              onChanged: (value) {
                setState(() => _highContrast = value);
                _savePreference('high_contrast', value);
              },
            ),

            const SizedBox(height: 24),

            // Taille de police
            _buildSettingSliderRow(
              icon: Icons.format_size,
              title: 'Taille de police',
              subtitle: 'Ajuster la taille du texte',
              value: _fontSize,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              onChanged: (value) {
                setState(() => _fontSize = value);
                _savePreference('font_size', value);
              },
            ),

            const SizedBox(height: 24),

            // Couleur du thème
            _buildSettingSelectionRow(
              icon: Icons.color_lens,
              title: 'Couleur du thème',
              subtitle: 'Choisir la couleur principale',
              value: _themeColor,
              options: ['Bleu', 'Vert', 'Violet', 'Orange', 'Rose'],
              onChanged: (value) {
                setState(() => _themeColor = value);
                _savePreference('theme_color', value);
                _showSuccessSnackbar('Couleur du thème changée pour $value');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confidentialité & Sécurité',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),

            const SizedBox(height: 20),

            // Analytics
            _buildSettingSwitchRow(
              icon: Icons.analytics,
              title: 'Analytics',
              subtitle:
                  'Partager des données d\'utilisation pour améliorer l\'app',
              value: _analyticsEnabled,
              onChanged: (value) {
                setState(() => _analyticsEnabled = value);
                _savePreference('analytics_enabled', value);
              },
            ),

            const SizedBox(height: 16),

            // Publicités personnalisées
            _buildSettingSwitchRow(
              icon: Icons.ads_click,
              title: 'Publicités personnalisées',
              subtitle: 'Afficher des publicités basées sur vos intérêts',
              value: _personalizedAds,
              onChanged: (value) {
                setState(() => _personalizedAds = value);
                _savePreference('personalized_ads', value);
              },
            ),

            const SizedBox(height: 16),

            // Partage de données
            _buildSettingSwitchRow(
              icon: Icons.share,
              title: 'Partage de données',
              subtitle: 'Partager des données anonymes avec nos partenaires',
              value: _dataSharing,
              onChanged: (value) {
                setState(() => _dataSharing = value);
                _savePreference('data_sharing', value);
              },
            ),

            const SizedBox(height: 16),

            // Statut en ligne
            _buildSettingSwitchRow(
              icon: Icons.online_prediction,
              title: 'Statut en ligne',
              subtitle:
                  'Afficher votre statut en ligne aux autres utilisateurs',
              value: _showOnlineStatus,
              onChanged: (value) {
                setState(() => _showOnlineStatus = value);
                _savePreference('show_online_status', value);
              },
            ),

            const SizedBox(height: 24),

            // Actions de confidentialité
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.privacy_tip,
                    label: 'Politique de confidentialité',
                    color: const Color(0xFF4A6572),
                    onTap: _launchPrivacyPolicy,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.description,
                    label: 'Conditions d\'utilisation',
                    color: const Color(0xFF4A6572),
                    onTap: _launchTermsOfService,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),

            const SizedBox(height: 20),

            // Notifications email
            _buildSettingSwitchRow(
              icon: Icons.email,
              title: 'Notifications par email',
              subtitle: 'Recevoir des notifications par email',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() => _emailNotifications = value);
                _savePreference('email_notifications', value);
              },
            ),

            const SizedBox(height: 16),

            // Notifications push
            _buildSettingSwitchRow(
              icon: Icons.notifications,
              title: 'Notifications push',
              subtitle: 'Recevoir des notifications sur votre appareil',
              value: _pushNotifications,
              onChanged: (value) {
                setState(() => _pushNotifications = value);
                _savePreference('push_notifications', value);
              },
            ),

            const SizedBox(height: 16),

            // Notifications SMS
            _buildSettingSwitchRow(
              icon: Icons.sms,
              title: 'Notifications SMS',
              subtitle: 'Recevoir des notifications par SMS',
              value: _smsNotifications,
              onChanged: (value) {
                setState(() => _smsNotifications = value);
                _savePreference('sms_notifications', value);
              },
            ),

            const SizedBox(height: 24),

            // Fréquence des notifications
            _buildSettingSelectionRow(
              icon: Icons.schedule,
              title: 'Fréquence des notifications',
              subtitle: 'Contrôler la fréquence des notifications',
              value: _notificationFrequency,
              options: ['Réel', 'Quotidien', 'Hebdomadaire', 'Jamais'],
              onChanged: (value) {
                setState(() => _notificationFrequency = value);
                _savePreference('notification_frequency', value);
                _showSuccessSnackbar('Fréquence changée pour $value');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Langue & Région',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),

            const SizedBox(height: 20),

            // Langue
            _buildSettingSelectionRow(
              icon: Icons.language,
              title: 'Langue',
              subtitle: 'Langue de l\'interface',
              value: _selectedLanguage,
              options: [
                'Français',
                'English',
                'Español',
                'Deutsch',
                'Italiano',
                'Português',
              ],
              onChanged: (value) {
                setState(() => _selectedLanguage = value);
                _savePreference('language', value);
                _showSuccessSnackbar('Langue changée pour $value');
              },
            ),

            const SizedBox(height: 16),

            // Région
            _buildSettingSelectionRow(
              icon: Icons.public,
              title: 'Région',
              subtitle: 'Paramètres régionaux',
              value: _selectedRegion,
              options: ['France', 'Canada', 'Belgique', 'Suisse', 'Autre'],
              onChanged: (value) {
                setState(() => _selectedRegion = value);
                _savePreference('region', value);
                _showSuccessSnackbar('Région changée pour $value');
              },
            ),

            const SizedBox(height: 16),

            // Format de date
            _buildSettingSelectionRow(
              icon: Icons.calendar_today,
              title: 'Format de date',
              subtitle: 'Format d\'affichage des dates',
              value: _dateFormat,
              options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
              onChanged: (value) {
                setState(() => _dateFormat = value);
                _savePreference('date_format', value);
              },
            ),

            const SizedBox(height: 16),

            // Format d'heure
            _buildSettingSelectionRow(
              icon: Icons.access_time,
              title: 'Format d\'heure',
              subtitle: 'Format d\'affichage des heures',
              value: _timeFormat,
              options: ['24h', '12h'],
              onChanged: (value) {
                setState(() => _timeFormat = value);
                _savePreference('time_format', value);
              },
            ),

            const SizedBox(height: 16),

            // Unité de température
            _buildSettingSelectionRow(
              icon: Icons.thermostat,
              title: 'Unité de température',
              subtitle: 'Unité d\'affichage de la température',
              value: _temperatureUnit,
              options: ['Celsius', 'Fahrenheit'],
              onChanged: (value) {
                setState(() => _temperatureUnit = value);
                _savePreference('temperature_unit', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSettings() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stockage & Données',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),

            const SizedBox(height: 20),

            // Mise à jour automatique
            _buildSettingSwitchRow(
              icon: Icons.system_update,
              title: 'Mise à jour automatique',
              subtitle: 'Mettre à jour l\'application automatiquement',
              value: _autoUpdate,
              onChanged: (value) {
                setState(() => _autoUpdate = value);
                _savePreference('auto_update', value);
              },
            ),

            const SizedBox(height: 16),

            // Synchronisation en arrière-plan
            _buildSettingSwitchRow(
              icon: Icons.sync,
              title: 'Synchronisation en arrière-plan',
              subtitle: 'Synchroniser les données en arrière-plan',
              value: _backgroundSync,
              onChanged: (value) {
                setState(() => _backgroundSync = value);
                _savePreference('background_sync', value);
              },
            ),

            const SizedBox(height: 16),

            // Cache
            _buildSettingSwitchRow(
              icon: Icons.storage,
              title: 'Cache',
              subtitle:
                  'Stocker les données en cache pour un accès plus rapide',
              value: _cacheEnabled,
              onChanged: (value) {
                setState(() => _cacheEnabled = value);
                _savePreference('cache_enabled', value);
              },
            ),

            const SizedBox(height: 24),

            // Qualité vidéo
            _buildSettingSelectionRow(
              icon: Icons.video_settings,
              title: 'Qualité vidéo',
              subtitle: 'Qualité des vidéos streamées',
              value: _videoQuality,
              options: ['Auto', 'Basse', 'Moyenne', 'Haute', 'Max'],
              onChanged: (value) {
                setState(() => _videoQuality = value);
                _savePreference('video_quality', value);
              },
            ),

            const SizedBox(height: 16),

            // Qualité de téléchargement
            _buildSettingSelectionRow(
              icon: Icons.download,
              title: 'Qualité de téléchargement',
              subtitle: 'Qualité des contenus téléchargés',
              value: _downloadQuality,
              options: ['Basse', 'Moyenne', 'Haute'],
              onChanged: (value) {
                setState(() => _downloadQuality = value);
                _savePreference('download_quality', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'À propos & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                fontFamily: 'OpenSans',
              ),
            ),

            const SizedBox(height: 20),

            // Version
            _buildInfoRow(
              icon: Icons.info,
              title: 'Version',
              value: '1.2.3 (Build 456)',
            ),

            const SizedBox(height: 16),

            // Dernière mise à jour
            _buildInfoRow(
              icon: Icons.update,
              title: 'Dernière mise à jour',
              value: '15 décembre 2023',
            ),

            const SizedBox(height: 16),

            // Support
            _buildInfoRow(
              icon: Icons.support_agent,
              title: 'Support',
              value: 'support@moodia.com',
              isClickable: true,
              onTap: () async {
                final url = Uri.parse('mailto:support@moodia.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  _showNotImplementedSnackbar('Ouverture du support');
                }
              },
            ),

            const SizedBox(height: 16),

            // Site web
            _buildInfoRow(
              icon: Icons.public,
              title: 'Site web',
              value: 'https://moodia.com',
              isClickable: true,
              onTap: () async {
                final url = Uri.parse('https://moodia.com');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                } else {
                  _showNotImplementedSnackbar('Ouverture du site web');
                }
              },
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.help_outline,
                    label: 'Centre d\'aide',
                    color: const Color(0xFF7DBBC3),
                    onTap: _showHelpDialog,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.feedback,
                    label: 'Envoyer un avis',
                    color: const Color(0xFF7DBBC3),
                    onTap: () {
                      _showNotImplementedSnackbar('Envoi d\'avis');
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

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations système',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.2.3 • 156.2 MB',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dernière mise à jour : 15/12/23',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportSettings,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exporter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7DBBC3),
                  side: const BorderSide(color: Color(0xFF7DBBC3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importSettings,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Importer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7DBBC3),
                  side: const BorderSide(color: Color(0xFF7DBBC3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showResetDialog,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Réinitialiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7DBBC3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF7DBBC3)),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7DBBC3),
            activeTrackColor: const Color(0xFF7DBBC3).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSliderRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DBBC3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF7DBBC3)),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7DBBC3),
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: const Color(0xFF7DBBC3),
            inactiveColor: const Color(0xFF7DBBC3).withOpacity(0.3),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Petit',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'OpenSans',
                ),
              ),
              Text(
                'Normal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'OpenSans',
                ),
              ),
              Text(
                'Grand',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSelectionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DBBC3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF7DBBC3)),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                onSelected: onChanged,
                itemBuilder: (context) {
                  return options.map((option) {
                    return PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (option == value)
                            const Icon(
                              Icons.check,
                              color: Color(0xFF7DBBC3),
                              size: 20,
                            )
                          else
                            const SizedBox(width: 20),
                          const SizedBox(width: 8),
                          Text(option),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF7DBBC3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isClickable ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7DBBC3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF7DBBC3)),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isClickable
                          ? const Color(0xFF7DBBC3)
                          : const Color(0xFF5D6D7E),
                      fontWeight: isClickable
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ],
              ),
            ),

            if (isClickable)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF7DBBC3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FBFC),
            appBar: AppBar(
              title: const Text('Paramètres'),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
              titleTextStyle: const TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'OpenSans',
              ),
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
            body: _buildDesktopLayout(),
            bottomNavigationBar: _buildBottomActions(),
          );
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }
}
