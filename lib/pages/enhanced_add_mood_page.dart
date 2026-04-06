// lib/pages/enhanced_add_mood_page.dart
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../models/emotion_model.dart';
import '../../models/mood_entry_enhanced.dart';
import '../../services/emotion_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedAddMoodPage extends StatefulWidget {
  const EnhancedAddMoodPage({Key? key}) : super(key: key);

  @override
  State<EnhancedAddMoodPage> createState() => _EnhancedAddMoodPageState();
}

class _EnhancedAddMoodPageState extends State<EnhancedAddMoodPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final EmotionApiService _emotionService = EmotionApiService();
  final ConfettiController _confettiController = ConfettiController();

  int? _userId;
  bool _isLoading = false;
  double _intensity = 5.0;
  int? _energyLevel;
  int? _sleepQuality;
  String? _selectedContext;
  List<String> _selectedTriggers = [];
  List<String> _selectedPhysicalSymptoms = [];
  List<String> _selectedCopingStrategies = [];
  String? _selectedPrimaryEmotion;
  List<String> _selectedSecondaryEmotions = [];

  // Données
  final List<String> _contextOptions = [
    'Travail',
    'Maison',
    'Social',
    'Transport',
    'Santé',
    'Famille',
    'Loisirs',
    'Autre',
  ];

  final List<String> _triggerOptions = [
    'Réunion importante',
    'Conflit relationnel',
    'Succès professionnel',
    'Problème santé',
    'Fatigue',
    'Météo',
    'Solitude',
    'Charge de travail',
    'Reconnaissance',
    'Critique',
    'Incertitude',
    'Changement',
  ];

  final List<String> _physicalSymptomsOptions = [
    'Tension musculaire',
    'Maux de tête',
    'Fatigue',
    'Agitation',
    'Palpitations',
    'Transpiration',
    'Nausée',
    'Tremblements',
    'Chaleur',
    'Froid',
    'Lourdeur',
    'Légèreté',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getInt('userId');
      });
    } catch (e) {
      debugPrint('Erreur chargement userId: $e');
    }
  }

  void _analyzeNote() async {
    if (_noteController.text.length < 10) return;

    setState(() => _isLoading = true);
    try {
      final analysis = await _emotionService.analyzeTextEmotion(
        _noteController.text,
      );

      // Mettre à jour l'émotion primaire suggérée
      final suggestedEmotion = analysis['dominantEmotion'] as String?;

      if (suggestedEmotion != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analyse suggérée: $suggestedEmotion'),
            backgroundColor: Colors.blue,
          ),
        );

        // Auto-sélectionner si pas déjà sélectionné
        if (_selectedPrimaryEmotion == null) {
          setState(() => _selectedPrimaryEmotion = suggestedEmotion);

          // Mettre à jour les stratégies d'adaptation
          final emotion = EmotionData.basicEmotions.firstWhere(
            (e) => e.name == suggestedEmotion,
            orElse: () => EmotionData.basicEmotions.first,
          );
          setState(() => _selectedCopingStrategies = emotion.copingStrategies);
        }
      }
    } catch (e) {
      debugPrint('Erreur analyse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'analyse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedPrimaryEmotion == null) {
      _showError('Veuillez sélectionner une émotion primaire');
      return;
    }

    if (_userId == null) {
      _showError('Utilisateur non identifié. Veuillez vous reconnecter.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newEntry = MoodEntryEnhanced(
        userId: _userId,
        primaryEmotion: _selectedPrimaryEmotion!,
        secondaryEmotions: _selectedSecondaryEmotions,
        intensity: _intensity,
        physicalSensations: {
          'symptoms': _selectedPhysicalSymptoms,
          'energy': _energyLevel,
          'sleep': _sleepQuality,
        },
        triggers: _selectedTriggers,
        note: _noteController.text.trim(),
        context: _selectedContext,
        copingStrategiesUsed: _selectedCopingStrategies,
        needSupport:
            _intensity > 8 &&
            [
              'Tristesse',
              'Colère',
              'Peur',
              'Anxiété',
            ].contains(_selectedPrimaryEmotion),
      );

      await _emotionService.saveEnhancedMoodEntry(newEntry);

      // Confetti pour les émotions positives
      if ([
        'Joie',
        'Amour',
        'Calme',
        'Surprise',
      ].contains(_selectedPrimaryEmotion)) {
        _confettiController.play();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Humeur enregistrée avec succès!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError("Erreur lors de l'enregistrement: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildEmotionWheel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionnez votre émotion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: EmotionData.basicEmotions.map((emotion) {
              final isSelected = _selectedPrimaryEmotion == emotion.name;
              final emotionColor = Color(emotion.color);

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emotion.emoji),
                    const SizedBox(width: 8),
                    Text(emotion.name),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPrimaryEmotion = emotion.name;
                      _selectedCopingStrategies = emotion.copingStrategies;
                    } else {
                      _selectedPrimaryEmotion = null;
                      _selectedCopingStrategies = [];
                    }
                  });
                },
                backgroundColor: emotionColor.withOpacity(0.1),
                selectedColor: emotionColor.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: isSelected ? emotionColor : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? emotionColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intensité émotionnelle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getIntensityColor(_intensity),
              inactiveTrackColor: Colors.grey[300],
              trackShape: const RectangularSliderTrackShape(),
              trackHeight: 4.0,
              thumbColor: _getIntensityColor(_intensity),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayColor: _getIntensityColor(_intensity).withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
              tickMarkShape: const RoundSliderTickMarkShape(),
              activeTickMarkColor: _getIntensityColor(_intensity),
              inactiveTickMarkColor: Colors.grey[300],
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: _getIntensityColor(_intensity),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: _intensity,
              min: 0,
              max: 10,
              divisions: 10,
              label: _intensity.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _intensity = value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sentiment_very_dissatisfied, color: Colors.red),
                  SizedBox(width: 8),
                  Text('0', style: TextStyle(color: Colors.grey)),
                ],
              ),
              Text(
                _getIntensityLabel(_intensity),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getIntensityColor(_intensity),
                ),
              ),
              const Row(
                children: [
                  Text('10', style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 8),
                  Icon(Icons.sentiment_very_satisfied, color: Colors.green),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (index) => Text(
                index == 0
                    ? 'Légère'
                    : index == 1
                    ? 'Modérée'
                    : 'Intense',
                style: TextStyle(
                  color: index == 0
                      ? Colors.blue
                      : index == 1
                      ? Colors.orange
                      : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(double value) {
    if (value < 3) return Colors.blue;
    if (value < 7) return Colors.orange;
    return Colors.red;
  }

  String _getIntensityLabel(double value) {
    if (value < 3) return 'Légère';
    if (value < 7) return 'Modérée';
    return 'Intense';
  }

  Widget _buildMultiSelectChips({
    required String title,
    required List<String> options,
    required List<String> selectedList,
    required Function(List<String>) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedList.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selectedValue) {
                  final newList = List<String>.from(selectedList);
                  if (selectedValue) {
                    newList.add(option);
                  } else {
                    newList.remove(option);
                  }
                  onChanged(newList);
                },
                backgroundColor: isSelected
                    ? Colors.deepPurple.withOpacity(0.1)
                    : Colors.grey[100],
                selectedColor: Colors.deepPurple.withOpacity(0.2),
                checkmarkColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.deepPurple : Colors.grey[700],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contexte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _contextOptions.map((context) {
              final isSelected = _selectedContext == context;
              return ChoiceChip(
                label: Text(context),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedContext = selected ? context : null;
                  });
                },
                backgroundColor: Colors.grey[100],
                selectedColor: Colors.blue.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySleepSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Niveau d\'énergie',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<int>(
                    value: _energyLevel,
                    items: List.generate(10, (i) => i + 1)
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              '$value/10',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _energyLevel = value);
                    },
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Sélectionner',
                      style: TextStyle(color: Colors.grey),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qualité du sommeil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<int>(
                    value: _sleepQuality,
                    items: List.generate(10, (i) => i + 1)
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              '$value/10',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _sleepQuality = value);
                    },
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Sélectionner',
                      style: TextStyle(color: Colors.grey),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Décrivez ce que vous ressentez, ce qui s\'est passé...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.deepPurple),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  color: _noteController.text.length >= 10
                      ? Colors.deepPurple
                      : Colors.grey,
                ),
                onPressed: _noteController.text.length >= 10
                    ? _analyzeNote
                    : null,
                tooltip: 'Analyser l\'émotion (min. 10 caractères)',
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_noteController.text.length}/500',
                style: TextStyle(
                  color: _noteController.text.length > 450
                      ? Colors.red
                      : Colors.grey,
                  fontWeight: _noteController.text.length > 450
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopingStrategiesSection() {
    if (_selectedCopingStrategies.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Stratégies suggérées',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCopingStrategies
                .map(
                  (strategy) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          strategy,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.purple.shade300,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sentiment_satisfied_alt,
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Comment vous sentez-vous?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Émotion Wheel
                _buildEmotionWheel(),

                // Intensité
                _buildIntensitySlider(),

                // Contexte
                _buildContextSelector(),

                // Triggers
                _buildMultiSelectChips(
                  title: 'Éléments déclencheurs',
                  options: _triggerOptions,
                  selectedList: _selectedTriggers,
                  onChanged: (list) {
                    setState(() => _selectedTriggers = list);
                  },
                ),

                // Symptômes physiques
                _buildMultiSelectChips(
                  title: 'Symptômes physiques',
                  options: _physicalSymptomsOptions,
                  selectedList: _selectedPhysicalSymptoms,
                  onChanged: (list) {
                    setState(() => _selectedPhysicalSymptoms = list);
                  },
                ),

                // Niveaux d'énergie et sommeil
                _buildEnergySleepSection(),

                // Notes
                _buildNotesSection(),

                // Stratégies d'adaptation
                _buildCopingStrategiesSection(),

                // Bouton de soumission
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor: Colors.deepPurple.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'ENREGISTRER L\'HUMEUR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.pink,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
