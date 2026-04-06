import 'dart:convert';

class Emotion {
  final String name;
  final String emoji;
  final double valence;
  final double arousal;
  final List<String> relatedEmotions;
  final List<String> physicalSymptoms;
  final List<String> copingStrategies;
  final int color;

  const Emotion({
    required this.name,
    required this.emoji,
    required this.valence,
    required this.arousal,
    required this.relatedEmotions,
    required this.physicalSymptoms,
    required this.copingStrategies,
    required this.color,
  });

  factory Emotion.fromJson(Map<String, dynamic> json) {
    return Emotion(
      name: json['name'],
      emoji: json['emoji'],
      valence: json['valence'].toDouble(),
      arousal: json['arousal'].toDouble(),
      relatedEmotions: List<String>.from(json['relatedEmotions']),
      physicalSymptoms: List<String>.from(json['physicalSymptoms']),
      copingStrategies: List<String>.from(json['copingStrategies']),
      color: int.parse(json['color'].replaceFirst('#', '0xFF')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emoji': emoji,
      'valence': valence,
      'arousal': arousal,
      'relatedEmotions': relatedEmotions,
      'physicalSymptoms': physicalSymptoms,
      'copingStrategies': copingStrategies,
      'color': '#${color.toRadixString(16).padLeft(8, '0').substring(2)}',
    };
  }

  String get intensityLevel {
    if (arousal.abs() > 0.7) return 'Élevée';
    if (arousal.abs() > 0.3) return 'Moyenne';
    return 'Faible';
  }

  bool get isPositive => valence > 0;
  bool get isNegative => valence < 0;
  bool get isNeutral => valence == 0;
}

class EmotionData {
  static final List<Emotion> basicEmotions = [
    Emotion(
      name: 'Joie',
      emoji: '😊',
      valence: 0.9,
      arousal: 0.7,
      relatedEmotions: ['Content', 'Enthousiaste', 'Fier'],
      physicalSymptoms: ['Sourire', 'Énergie élevée', 'Relaxation musculaire'],
      copingStrategies: ['Partager', 'Célébrer', 'Exprimer gratitude'],
      color: 0xFFFFC107,
    ),
    Emotion(
      name: 'Tristesse',
      emoji: '😢',
      valence: -0.8,
      arousal: -0.3,
      relatedEmotions: ['Mélancolique', 'Désespéré', 'Solitaire'],
      physicalSymptoms: ['Larmes', 'Fatigue', 'Lourdeur'],
      copingStrategies: ['Pleurer', 'Parler', 'Auto-compassion'],
      color: 0xFF2196F3,
    ),
    Emotion(
      name: 'Colère',
      emoji: '😠',
      valence: -0.7,
      arousal: 0.9,
      relatedEmotions: ['Frustré', 'Irrité', 'Ressentiment'],
      physicalSymptoms: [
        'Tension musculaire',
        'Chaleur',
        'Accélération cardiaque',
      ],
      copingStrategies: ['Respiration', 'Exercice', 'Communication assertive'],
      color: 0xFFF44336,
    ),
    Emotion(
      name: 'Peur',
      emoji: '😨',
      valence: -0.9,
      arousal: 0.8,
      relatedEmotions: ['Anxieux', 'Inquiet', 'Terrorisé'],
      physicalSymptoms: ['Tremblements', 'Sueurs', 'Dilatation pupilles'],
      copingStrategies: ['Grounding', 'Planification', 'Support social'],
      color: 0xFF9C27B0,
    ),
    Emotion(
      name: 'Dégoût',
      emoji: '🤢',
      valence: -0.6,
      arousal: 0.3,
      relatedEmotions: ['Mépris', 'Répulsion', 'Nausée'],
      physicalSymptoms: ['Nausée', 'Rejet', 'Contraction visage'],
      copingStrategies: ['Éviter source', 'Nettoyer', 'Distraction'],
      color: 0xFF4CAF50,
    ),
    Emotion(
      name: 'Surprise',
      emoji: '😲',
      valence: 0.0,
      arousal: 0.9,
      relatedEmotions: ['Stupéfait', 'Étonné', 'Choqué'],
      physicalSymptoms: [
        'Sursaut',
        'Écarquillement yeux',
        'Respiration coupée',
      ],
      copingStrategies: ['Prendre moment', 'Évaluer situation', 'Adapter'],
      color: 0xFFFF9800,
    ),
    Emotion(
      name: 'Calme',
      emoji: '😌',
      valence: 0.7,
      arousal: -0.8,
      relatedEmotions: ['Paisible', 'Serein', 'Détendu'],
      physicalSymptoms: [
        'Respiration lente',
        'Muscles détendus',
        'Rythme cardiaque régulier',
      ],
      copingStrategies: ['Méditation', 'Respiration profonde', 'Nature'],
      color: 0xFF00BCD4,
    ),
    Emotion(
      name: 'Amour',
      emoji: '❤️',
      valence: 1.0,
      arousal: 0.5,
      relatedEmotions: ['Affection', 'Tendresse', 'Attachement'],
      physicalSymptoms: [
        'Chaleur thoracique',
        'Sourire involontaire',
        'Relaxation',
      ],
      copingStrategies: ['Exprimer', 'Partager', 'Cultiver'],
      color: 0xFFE91E63,
    ),
  ];

  static Emotion getEmotionByName(String name) {
    return basicEmotions.firstWhere(
      (emotion) => emotion.name == name,
      orElse: () => basicEmotions.first,
    );
  }
}
