import 'package:flutter/material.dart';
import 'package:moodia/models/journal_entry.dart';
import 'package:moodia/services/journal_api_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'
    as syncfusion_flutter_gauges;
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class JournalStatisticsPage extends StatefulWidget {
  final int userId;

  const JournalStatisticsPage({super.key, required this.userId});

  @override
  State<JournalStatisticsPage> createState() => _JournalStatisticsPageState();
}

class _JournalStatisticsPageState extends State<JournalStatisticsPage> {
  final JournalApiService _journalService = JournalApiService();
  JournalStatistics? _statistics;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  int _selectedTimeRange = 30; // 7, 30, 90, 365 jours
  final List<int> _timeRanges = [7, 30, 90, 365];
  bool _isOnline = true;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadStatistics();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
      _connectionStatus = _isOnline ? '📶 En ligne' : '📴 Hors ligne';
    });
  }

  Future<void> _loadStatistics({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _journalService.getStatistics(
        widget.userId,
        forceRefresh: forceRefresh && _isOnline,
      );
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStatistics() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mode hors ligne : impossible de rafraîchir les données',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _isRefreshing = true);
    await _loadStatistics(forceRefresh: true);
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          'Statistiques',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // Indicateur de connexion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
            onPressed: _refreshStatistics,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _statistics == null
          ? _buildEmptyState()
          : _buildStatisticsContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(Colors.deepPurple.shade600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isOnline
                ? 'Analyse de vos données...'
                : 'Chargement depuis le cache...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Oups !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Pas encore de données',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Commencez à écrire dans votre journal pour voir vos statistiques',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    final stats = _statistics!;
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshStatistics,
      color: Colors.deepPurple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Période de temps
          _buildTimeRangeSelector(),
          const SizedBox(height: 20),

          // Vue d'ensemble avec jauges
          _buildOverviewSection(stats, theme),
          const SizedBox(height: 20),

          // Distribution par type
          _buildTypeDistributionSection(stats, theme),
          const SizedBox(height: 20),

          // Distribution par humeur
          if (stats.moodDistribution.isNotEmpty) ...[
            _buildMoodDistributionSection(stats, theme),
            const SizedBox(height: 20),
          ],

          // Activité hebdomadaire
          _buildWeeklyActivitySection(stats, theme),
          const SizedBox(height: 20),

          // Tags populaires
          if (stats.tagFrequency.isNotEmpty) ...[
            _buildPopularTagsSection(stats, theme),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Période :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Wrap(
              spacing: 8,
              children: _timeRanges.map((days) {
                final isSelected = _selectedTimeRange == days;
                return FilterChip(
                  label: Text('$days jours'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeRange = selected ? days : _selectedTimeRange;
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.deepPurple,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Les méthodes de construction des sections restent identiques à l'original
  Widget _buildOverviewSection(JournalStatistics stats, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vue d\'ensemble',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timeline, size: 16, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedTimeRange} jours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.book_outlined,
                    value: stats.totalEntries.toString(),
                    label: 'Entrées totales',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.text_fields_outlined,
                    value: stats.totalWords.toString(),
                    label: 'Mots écrits',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.timeline_outlined,
                    value: stats.longestStreak.toString(),
                    label: 'Série record',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildGauge(
                    title: 'Moyenne mots/entrée',
                    value: stats.averageWordsPerEntry.toDouble(),
                    max: 500,
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildGauge(
                    title: 'Taux d\'activité',
                    value: (stats.totalEntries / _selectedTimeRange) * 100,
                    max: 100,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGauge({
    required String title,
    required double value,
    required double max,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: syncfusion_flutter_gauges.SfRadialGauge(
            enableLoadingAnimation: true,
            animationDuration: 1500,
            axes: <syncfusion_flutter_gauges.RadialAxis>[
              syncfusion_flutter_gauges.RadialAxis(
                minimum: 0,
                maximum: max,
                showLabels: false,
                showTicks: false,
                axisLineStyle: syncfusion_flutter_gauges.AxisLineStyle(
                  thickness: 0.1,
                  cornerStyle: syncfusion_flutter_gauges.CornerStyle.bothCurve,
                  color: color.withOpacity(0.2),
                  thicknessUnit: syncfusion_flutter_gauges.GaugeSizeUnit.factor,
                ),
                pointers: <syncfusion_flutter_gauges.GaugePointer>[
                  syncfusion_flutter_gauges.RangePointer(
                    value: value,
                    cornerStyle:
                        syncfusion_flutter_gauges.CornerStyle.bothCurve,
                    width: 0.1,
                    sizeUnit: syncfusion_flutter_gauges.GaugeSizeUnit.factor,
                    color: color,
                    gradient: SweepGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                  ),
                ],
                annotations: <syncfusion_flutter_gauges.GaugeAnnotation>[
                  syncfusion_flutter_gauges.GaugeAnnotation(
                    widget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'sur $max',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDistributionSection(
    JournalStatistics stats,
    ThemeData theme,
  ) {
    final data = stats.entryTypeDistribution.entries
        .map((e) => _ChartData(e.key, e.value))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribution par type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Répartition de vos entrées par catégorie',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                palette: [
                  Colors.pink.shade400,
                  Colors.deepPurple.shade400,
                  Colors.blue.shade400,
                  Colors.orange.shade400,
                  Colors.yellow.shade600,
                  Colors.indigo.shade400,
                  Colors.green.shade400,
                  Colors.grey.shade400,
                ],
                series: <CircularSeries<_ChartData, String>>[
                  DoughnutSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData data, _) => data.type,
                    yValueMapper: (_ChartData data, _) => data.count,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(fontSize: 12),
                    ),
                    enableTooltip: true,
                    radius: '70%',
                    innerRadius: '40%',
                  ),
                ],
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistributionSection(
    JournalStatistics stats,
    ThemeData theme,
  ) {
    final data = stats.moodDistribution.entries
        .map((e) => _ChartData(e.key.toString(), e.value))
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution de l\'humeur',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Progression de votre état émotionnel',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value.count.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.moodDistribution.entries.map((entry) {
                final rating = entry.key;
                final count = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getMoodColor(rating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getMoodColor(rating).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMoodIcon(rating),
                        size: 16,
                        color: _getMoodColor(rating),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$rating/10: $count fois',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getMoodColor(rating),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivitySection(JournalStatistics stats, ThemeData theme) {
    const daysOrder = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    final sortedData = stats.entriesByDayOfWeek.entries.toList()
      ..sort(
        (a, b) => daysOrder.indexOf(a.key).compareTo(daysOrder.indexOf(b.key)),
      );

    final chartData = sortedData
        .map((e) => _ChartData(e.key.substring(0, 3), e.value))
        .toList();

    final maxValue = chartData.isNotEmpty
        ? chartData.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activité hebdomadaire',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Quand écrivez-vous le plus ?',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                  labelStyle: TextStyle(fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: maxValue.toDouble() + 1,
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                series: <ColumnSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.type,
                    yValueMapper: (_ChartData data, _) => data.count,
                    color: Colors.deepPurple,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    width: 0.6,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: daysOrder.map((day) {
                final value = stats.entriesByDayOfWeek[day] ?? 0;
                final percentage = maxValue > 0 ? (value / maxValue) * 100 : 0;
                return Column(
                  children: [
                    Text(
                      day.substring(0, 3),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 30,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey.shade200,
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 30,
                            height: percentage.toDouble(),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.deepPurple.shade600,
                                  Colors.deepPurple.shade400,
                                ],
                              ),
                            ),
                          ),
                          if (value > 0)
                            Positioned(
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  value.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularTagsSection(JournalStatistics stats, ThemeData theme) {
    final popularTags = stats.tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mots-clés populaires',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        '${popularTags.length} tags',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Les thèmes qui reviennent le plus souvent',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popularTags.take(15).map((entry) {
                final percentage = (entry.value / stats.totalEntries) * 100;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '#${entry.key}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value} fois • ${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (popularTags.length > 15) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '... et ${popularTags.length - 15} autres',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(int rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.lightGreen;
    if (rating >= 4) return Colors.orange;
    if (rating >= 2) return Colors.orangeAccent;
    return Colors.red;
  }

  IconData _getMoodIcon(int rating) {
    if (rating >= 8) return Icons.sentiment_very_satisfied;
    if (rating >= 6) return Icons.sentiment_satisfied;
    if (rating >= 4) return Icons.sentiment_neutral;
    if (rating >= 2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }
}

class _ChartData {
  final String type;
  final int count;

  _ChartData(this.type, this.count);
}
