// lib/screens/emotion/emotion_dashboard.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/emotion_api_service.dart';
import '../../models/mood_entry_enhanced.dart';
import 'enhanced_add_mood_page.dart';
import 'coping_strategies_page.dart';

class EmotionDashboard extends StatefulWidget {
  const EmotionDashboard({Key? key}) : super(key: key);

  @override
  State<EmotionDashboard> createState() => _EmotionDashboardState();
}

class _EmotionDashboardState extends State<EmotionDashboard> {
  late EmotionApiService _emotionService;
  List<MoodEntryEnhanced> _entries = [];
  List<MoodEntryEnhanced> _cachedEntries = [];
  bool _isLoading = true;
  int _selectedTimeFilter = 0; // 0: 7 jours, 1: 30 jours, 2: 90 jours

  // État de la connexion
  bool _isOnline = true;
  String? _connectionStatus;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  int? _userId;

  // Données pour les graphiques
  Map<String, int> _emotionCounts = {};
  List<Map<String, dynamic>> _intensityTrend = [];
  Map<String, double> _contextDistribution = {};
  Map<String, double> _timeOfDayDistribution = {};

  // Couleurs de l'application
  static const Color _primaryColor = Color(0xFF2C3E50);
  static const Color _secondaryColor = Color(0xFF3498DB);
  static const Color _accentColor = Color(0xFF1ABC9C);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _positiveColor = Color(0xFF27AE60);
  static const Color _neutralColor = Color(0xFF7F8C8D);
  static const Color _negativeColor = Color(0xFFE74C3C);
  static const Color _borderColor = Color(0xFFECF0F1);

  // Palette pour les graphiques
  final List<Color> _chartColors = [
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFE74C3C),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFF39C12),
    Color(0xFF34495E),
    Color(0xFF95A5A6),
  ];

  @override
  void initState() {
    super.initState();
    _emotionService = EmotionApiService();
    _initConnectivity();
    _initializeData();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
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

  Future<void> _initializeData() async {
    await _loadUserId();
    await _loadData();
  }

  // ========== GESTION DU CACHE ==========
  Future<void> _saveEntriesToCache(List<MoodEntryEnhanced> entries) async {
    if (_userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = entries.map((e) => e.toJson()).toList();
      await prefs.setString(
        'cached_emotions_$_userId',
        jsonEncode(entriesJson),
      );
      if (kDebugMode)
        print('💾 Émotions sauvegardées en cache (${entries.length} entrées)');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde cache émotions: $e');
    }
  }

  Future<List<MoodEntryEnhanced>> _loadEntriesFromCache() async {
    if (_userId == null) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_emotions_$_userId');
      if (jsonString == null) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final entries = jsonList
          .map(
            (json) => MoodEntryEnhanced.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      if (kDebugMode)
        print('📦 Émotions chargées depuis cache (${entries.length} entrées)');
      return entries;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cache émotions: $e');
      // Si cache corrompu, on le supprime
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_emotions_$_userId');
      return [];
    }
  }

  // ========== SYNCHRONISATION ==========
  Future<void> _syncEntries() async {
    if (!_isOnline || _userId == null) return;
    if (kDebugMode) print('🔄 Synchronisation des émotions...');

    try {
      // Récupérer toutes les entrées depuis l'API
      final allEntries = await _emotionService.getEnhancedMoodEntries();

      if (allEntries.isNotEmpty) {
        await _saveEntriesToCache(allEntries);
        if (mounted) {
          setState(() {
            _entries = allEntries;
            _cachedEntries = allEntries;
            _isLoading = false;
          });
          _analyzeData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Données synchronisées'),
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

  // ========== CHARGEMENT DES DONNÉES ==========
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (_isOnline) {
      try {
        // Charger depuis l'API
        final entries = await _emotionService.getEnhancedMoodEntries();
        setState(() {
          _entries = entries;
          _cachedEntries = entries;
          _isLoading = false;
        });
        // Sauvegarder en cache
        await _saveEntriesToCache(entries);
        _analyzeData();
      } catch (e) {
        if (kDebugMode) print('❌ Erreur chargement en ligne: $e');
        // En cas d'erreur réseau, utiliser le cache
        final cached = await _loadEntriesFromCache();
        if (cached.isNotEmpty) {
          setState(() {
            _entries = cached;
            _cachedEntries = cached;
            _isLoading = false;
          });
          _analyzeData();
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de chargement : $e'),
              backgroundColor: Colors.red,
            ),
          );
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
        });
        _analyzeData();
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode hors ligne : aucune donnée en cache'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ========== ANALYSE DES DONNÉES ==========
  void _analyzeData() {
    if (_entries.isEmpty) return;

    // Filtrer selon la période
    final days = _getDaysForFilter();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredEntries = _entries
        .where(
          (entry) =>
              entry.createdAt != null && entry.createdAt!.isAfter(cutoffDate),
        )
        .toList();

    if (kDebugMode) {
      print(
        '📊 _analyzeData: ${_entries.length} total, '
        '${filteredEntries.length} après filtre (${_getFilterLabel()})',
      );
    }

    if (filteredEntries.isEmpty) return;

    // Comptage des émotions
    _emotionCounts = {};
    for (var entry in filteredEntries) {
      _emotionCounts.update(
        entry.primaryEmotion,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Tendance d'intensité
    _intensityTrend = filteredEntries
        .where((entry) => entry.createdAt != null)
        .map(
          (entry) => {
            'date': entry.createdAt!,
            'intensity': entry.intensity,
            'emotion': entry.primaryEmotion,
          },
        )
        .toList();

    _intensityTrend.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateA.compareTo(dateB);
    });

    // Distribution des contextes
    _contextDistribution = {};
    final contexts = filteredEntries
        .where((entry) => entry.context != null && entry.context!.isNotEmpty)
        .toList();
    for (var entry in contexts) {
      _contextDistribution.update(
        entry.context!,
        (value) => value + 1,
        ifAbsent: () => 1.0,
      );
    }

    // Distribution par heure
    _timeOfDayDistribution = {
      'Matin (5h-12h)': 0.0,
      'Après-midi (12h-18h)': 0.0,
      'Soir (18h-22h)': 0.0,
      'Nuit (22h-5h)': 0.0,
    };

    for (var entry in filteredEntries) {
      if (entry.createdAt != null) {
        final hour = entry.createdAt!.hour;
        String timeSlot;
        if (hour >= 5 && hour < 12)
          timeSlot = 'Matin (5h-12h)';
        else if (hour >= 12 && hour < 18)
          timeSlot = 'Après-midi (12h-18h)';
        else if (hour >= 18 && hour < 22)
          timeSlot = 'Soir (18h-22h)';
        else
          timeSlot = 'Nuit (22h-5h)';

        _timeOfDayDistribution[timeSlot] =
            (_timeOfDayDistribution[timeSlot] ?? 0) + 1.0;
        if (kDebugMode) {
          print(
            '🕒 Heure ${entry.createdAt!.hour} → $timeSlot (${entry.primaryEmotion})',
          );
        }
      } else {
        if (kDebugMode) print('⚠️ Entrée sans createdAt: ${entry.id}');
      }
    }

    if (kDebugMode) {
      print('📊 Distribution finale: $_timeOfDayDistribution');
    }
  }

  // ========== MÉTHODES UTILITAIRES ==========
  int _getDaysForFilter() {
    switch (_selectedTimeFilter) {
      case 0:
        return 7;
      case 1:
        return 30;
      case 2:
        return 90;
      default:
        return 7;
    }
  }

  String _getFilterLabel() {
    switch (_selectedTimeFilter) {
      case 0:
        return '7 derniers jours';
      case 1:
        return '30 derniers jours';
      case 2:
        return '90 derniers jours';
      default:
        return '7 derniers jours';
    }
  }

  // ========== WIDGETS UI ==========
  Widget _buildHeader() {
    final positiveEmotions = [
      'Joie',
      'Amour',
      'Calme',
      'Surprise',
      'Heureux',
      'Joyeux',
      'Content',
      'Énergique',
      'Serein',
    ];
    final negativeEmotions = [
      'Tristesse',
      'Colère',
      'Peur',
      'Anxiété',
      'Triste',
      'En colère',
      'Anxieux',
      'Stressé',
      'Frustré',
    ];

    int positiveCount = 0;
    int negativeCount = 0;
    double avgIntensity = 0;

    if (_entries.isNotEmpty) {
      final days = _getDaysForFilter();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final filteredEntries = _entries
          .where(
            (entry) =>
                entry.createdAt != null && entry.createdAt!.isAfter(cutoffDate),
          )
          .toList();

      for (var entry in filteredEntries) {
        avgIntensity += entry.intensity;
        if (positiveEmotions.contains(entry.primaryEmotion)) {
          positiveCount++;
        } else if (negativeEmotions.contains(entry.primaryEmotion)) {
          negativeCount++;
        }
      }
      if (filteredEntries.isNotEmpty) {
        avgIntensity = avgIntensity / filteredEntries.length;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, Color(0xFF34495E)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Émotionnel',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_entries.length} entrées analysées • ${_getFilterLabel()}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatChip(
                  'Intensité Moyenne',
                  '${avgIntensity.toStringAsFixed(1)}/10',
                  _getIntensityColor(avgIntensity),
                  Icons.trending_up_outlined,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Positives',
                  '$positiveCount',
                  _positiveColor,
                  Icons.arrow_upward_outlined,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Négatives',
                  '$negativeCount',
                  _negativeColor,
                  Icons.arrow_downward_outlined,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  'Ratio Pos/Neg',
                  positiveCount + negativeCount > 0
                      ? '${(positiveCount / (positiveCount + negativeCount) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  _secondaryColor,
                  Icons.balance_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution() {
    final data = _emotionCounts.entries.toList();
    data.sort((a, b) => b.value.compareTo(a.value));

    if (data.isEmpty) {
      return _buildEmptyState(
        'Commencez à enregistrer vos émotions pour voir leur distribution.',
        Icons.pie_chart_outline,
      );
    }

    final total = data.fold<int>(0, (sum, element) => sum + element.value);

    return _buildChartCard(
      title: 'Distribution des Émotions',
      icon: Icons.pie_chart_outline_outlined,
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  sections: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final emotionData = entry.value;
                    final percentage = (emotionData.value / total * 100);

                    return PieChartSectionData(
                      color: _chartColors[index % _chartColors.length],
                      value: emotionData.value.toDouble(),
                      title: percentage >= 5
                          ? '${percentage.toStringAsFixed(0)}%'
                          : '',
                      radius: 30,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 45,
                  sectionsSpace: 1,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                // ← Ajouter ceci pour permettre le défilement
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((emotionData) {
                    final index = data.indexOf(emotionData);
                    final percentage = (emotionData.value / total * 100);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _chartColors[index % _chartColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emotionData.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textColor,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: _borderColor,
                                  color:
                                      _chartColors[index % _chartColors.length],
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${emotionData.value}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textColor,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _textColor.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityTrend() {
    if (_intensityTrend.isEmpty) {
      return _buildEmptyState(
        'Enregistrez vos émotions pour suivre leur évolution dans le temps.',
        Icons.timeline_outlined,
      );
    }

    return _buildChartCard(
      title: 'Évolution de l\'Intensité',
      icon: Icons.timeline_outlined,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: _borderColor, strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _textColor.withOpacity(0.6),
                          fontFamily: 'Roboto',
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (_intensityTrend.isNotEmpty &&
                        value.toInt() < _intensityTrend.length &&
                        value.toInt() % (_intensityTrend.length > 10 ? 3 : 1) ==
                            0) {
                      final date =
                          _intensityTrend[value.toInt()]['date'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: _textColor.withOpacity(0.6),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: _borderColor, width: 1),
            ),
            minX: 0,
            maxX: (_intensityTrend.length - 1).toDouble(),
            minY: 0,
            maxY: 10,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final index = touchedSpot.x.toInt();
                    if (index < _intensityTrend.length) {
                      final date = _intensityTrend[index]['date'] as DateTime;
                      final emotion =
                          _intensityTrend[index]['emotion'] as String;
                      return LineTooltipItem(
                        '${DateFormat('dd/MM').format(date)}\n'
                        'Intensité: ${touchedSpot.y.toStringAsFixed(1)}\n'
                        'Émotion: $emotion',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      );
                    }
                    return const LineTooltipItem('', TextStyle());
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _intensityTrend.asMap().entries.map((entry) {
                  final intensity = entry.value['intensity'] as double;
                  return FlSpot(entry.key.toDouble(), intensity);
                }).toList(),
                isCurved: true,
                color: _secondaryColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: _secondaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      _secondaryColor.withOpacity(0.3),
                      _secondaryColor.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextAnalysis() {
    final data = _contextDistribution.entries.toList();
    data.sort((a, b) => b.value.compareTo(a.value));

    if (data.isEmpty) {
      return _buildEmptyState(
        'Ajoutez des contextes à vos émotions pour mieux comprendre vos patterns.',
        Icons.location_on_outlined,
      );
    }

    final maxValue = data.isNotEmpty
        ? data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1
        : 10.0;

    return _buildChartCard(
      title: 'Émotions par Contexte',
      icon: Icons.location_on_outlined,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: maxValue,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.blueGrey,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final contextName = data[groupIndex].key;
                  final occurrences = rod.toY;
                  return BarTooltipItem(
                    '$contextName\n'
                    '${occurrences.toInt()} occurrence${occurrences > 1 ? 's' : ''}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < data.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: 70,
                          child: Text(
                            data[value.toInt()].key,
                            style: TextStyle(
                              fontSize: 10,
                              color: _textColor.withOpacity(0.6),
                              fontFamily: 'Roboto',
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxValue > 5 ? (maxValue / 5) : 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: _textColor.withOpacity(0.6),
                        fontFamily: 'Roboto',
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue > 5 ? (maxValue / 5) : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: _borderColor, strokeWidth: 1);
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: _borderColor, width: 1),
            ),
            barGroups: data.asMap().entries.map((entry) {
              final index = entry.key;
              final contextData = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: contextData.value,
                    color: _chartColors[index % _chartColors.length],
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOfDayAnalysis() {
    final data = _timeOfDayDistribution.entries.toList();

    return _buildChartCard(
      title: 'Distribution par Moment',
      icon: Icons.access_time_outlined,
      child: SizedBox(
        height: 320, // ← hauteur augmentée pour éviter le débordement
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final timeData = data[index];
                  final total = data.fold<double>(
                    0,
                    (sum, element) => sum + element.value,
                  );
                  final percentage = total > 0
                      ? (timeData.value / total * 100)
                      : 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            timeData.key,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: percentage / 100,
                                        backgroundColor: _borderColor,
                                        color:
                                            _chartColors[index %
                                                _chartColors.length],
                                        borderRadius: BorderRadius.circular(4),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 45,
                                      child: Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _textColor,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Roboto',
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${timeData.value.toInt()} occurrence${timeData.value.toInt() > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textColor.withOpacity(0.6),
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildRecentEntries() {
    if (_entries.isEmpty) {
      return _buildEmptyState(
        'Commencez à enregistrer vos émotions pour voir votre historique.',
        Icons.history_outlined,
      );
    }

    final recentEntries = _entries.take(3).toList();

    return _buildChartCard(
      title: 'Dernières Entrées',
      icon: Icons.history_outlined,
      child: Column(
        children: recentEntries.map((entry) {
          final emotionColor = _getEmotionColor(entry.primaryEmotion);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: emotionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: emotionColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getEmojiForEmotion(entry.primaryEmotion),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.primaryEmotion,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getIntensityColor(
                                entry.intensity,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getIntensityColor(
                                  entry.intensity,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 12,
                                  color: _getIntensityColor(entry.intensity),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.intensity.toStringAsFixed(1)}/10',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getIntensityColor(entry.intensity),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (entry.secondaryEmotions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: entry.secondaryEmotions.map((emotion) {
                            return Chip(
                              label: Text(
                                emotion,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _textColor.withOpacity(0.8),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              backgroundColor: _getEmotionColor(
                                emotion,
                              ).withOpacity(0.1),
                              side: BorderSide(
                                color: _getEmotionColor(
                                  emotion,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (entry.note != null && entry.note!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.note!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _textColor.withOpacity(0.7),
                            fontFamily: 'Roboto',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (entry.context != null &&
                              entry.context!.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: _textColor.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.context!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textColor.withOpacity(0.5),
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                          ],
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: _textColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: _textColor.withOpacity(0.5),
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _textColor.withOpacity(0.3),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CopingStrategiesPage(
                          emotionName: entry.primaryEmotion,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewAllEntriesButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextButton.icon(
        onPressed: () {
          _showAllEntriesModal();
        },
        icon: Icon(Icons.history, color: _primaryColor),
        label: Text(
          'Voir tout l\'historique',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: _primaryColor.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _primaryColor.withOpacity(0.2), width: 1),
          ),
        ),
      ),
    );
  }

  void _showAllEntriesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historique Complet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textColor.withOpacity(0.6)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 64,
                              color: _textColor.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune entrée disponible',
                              style: TextStyle(
                                fontSize: 16,
                                color: _textColor.withOpacity(0.5),
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _buildDetailedEntryCard(entry);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedEntryCard(MoodEntryEnhanced entry) {
    final emotionColor = _getEmotionColor(entry.primaryEmotion);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: emotionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: emotionColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  entry.primaryEmotion,
                  style: TextStyle(
                    fontSize: 14,
                    color: emotionColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.createdAt != null
                        ? DateFormat('dd/MM/yyyy').format(entry.createdAt!)
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textColor.withOpacity(0.6),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Text(
                    entry.createdAt != null
                        ? DateFormat('HH:mm').format(entry.createdAt!)
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _textColor.withOpacity(0.4),
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entry.secondaryEmotions.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: entry.secondaryEmotions.map((emotion) {
                return Chip(
                  label: Text(
                    emotion,
                    style: TextStyle(
                      fontSize: 11,
                      color: _textColor.withOpacity(0.8),
                      fontFamily: 'Roboto',
                    ),
                  ),
                  backgroundColor: _getEmotionColor(emotion).withOpacity(0.05),
                  side: BorderSide(
                    color: _getEmotionColor(emotion).withOpacity(0.2),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.note != null && entry.note!.isNotEmpty) ...[
                      Text(
                        'Note:',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _textColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (entry.context != null && entry.context!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: _textColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Contexte: ${entry.context!}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textColor.withOpacity(0.7),
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(
                        entry.intensity,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getIntensityColor(
                          entry.intensity,
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Intensité',
                          style: TextStyle(
                            fontSize: 10,
                            color: _textColor.withOpacity(0.6),
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.intensity.toStringAsFixed(1)}/10',
                          style: TextStyle(
                            fontSize: 16,
                            color: _getIntensityColor(entry.intensity),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CopingStrategiesPage(
                            emotionName: entry.primaryEmotion,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Stratégies',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: _textColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: _textColor.withOpacity(0.5),
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EnhancedAddMoodPage()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter une entrée'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterOption('7 jours', 0),
          _buildFilterOption('30 jours', 1),
          _buildFilterOption('90 jours', 2),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, int value) {
    final isSelected = _selectedTimeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTimeFilter = value;
            _analyzeData();
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : _textColor.withOpacity(0.6),
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Dashboard Émotionnel',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        actions: [
          // Indicateur de connexion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (_isOnline ? Colors.green : Colors.orange).withOpacity(
                  0.2,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_isOnline ? Colors.green : Colors.orange).withOpacity(
                    0.5,
                  ),
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
            icon: const Icon(Icons.refresh_outlined, color: Color(0xFF2C3E50)),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF2C3E50)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export des données (bientôt disponible)'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 20),
                  Text(
                    'Analyse de vos données...',
                    style: TextStyle(
                      fontSize: 16,
                      color: _textColor.withOpacity(0.6),
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildTimeFilter(),
                  const SizedBox(height: 20),
                  _buildEmotionDistribution(),
                  _buildIntensityTrend(),
                  _buildContextAnalysis(),
                  _buildTimeOfDayAnalysis(),
                  _buildRecentEntries(),
                  _buildViewAllEntriesButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnhancedAddMoodPage()),
          );
        },
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_outlined),
        label: const Text(
          'Nouvelle entrée',
          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
        ),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========== UTILITAIRES ==========
  String _getEmojiForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joie':
      case 'heureux':
      case 'joyeux':
      case 'content':
        return '😊';
      case 'tristesse':
        return '😢';
      case 'colère':
        return '😠';
      case 'peur':
        return '😨';
      case 'amour':
        return '❤️';
      case 'calme':
        return '😌';
      case 'surprise':
        return '😲';
      case 'anxiété':
        return '😰';
      default:
        return '😐';
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joie':
      case 'heureux':
      case 'joyeux':
      case 'content':
        return _positiveColor;
      case 'amour':
        return const Color(0xFFE74C3C);
      case 'calme':
      case 'serein':
        return const Color(0xFF3498DB);
      case 'surprise':
        return const Color(0xFFF39C12);
      case 'tristesse':
      case 'triste':
        return const Color(0xFF2980B9);
      case 'colère':
      case 'en colère':
        return const Color(0xFFC0392B);
      case 'peur':
        return const Color(0xFF8E44AD);
      case 'anxiété':
      case 'anxieux':
        return const Color(0xFF7D3C98);
      default:
        return _neutralColor;
    }
  }

  Color _getIntensityColor(double intensity) {
    if (intensity < 3)
      return const Color(0xFF27AE60);
    else if (intensity < 7)
      return const Color(0xFFF39C12);
    else
      return const Color(0xFFE74C3C);
  }
}
