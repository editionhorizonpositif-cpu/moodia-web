// lib/screens/emotion/coping_strategies_page.dart
import 'package:flutter/material.dart';
import '../../models/emotion_model.dart';

class CopingStrategiesPage extends StatelessWidget {
  final String emotionName;

  const CopingStrategiesPage({Key? key, required this.emotionName})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emotion = EmotionData.basicEmotions.firstWhere(
      (e) => e.name == emotionName,
      orElse: () => EmotionData.basicEmotions.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Stratégies pour $emotionName'),
        backgroundColor: Color(emotion.color),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(emotion.color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(emotion.color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(emotion.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emotion.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(emotion.color),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Intensité: ${emotion.intensityLevel}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stratégies d'adaptation
            const Text(
              'Stratégies recommandées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            ...emotion.copingStrategies.asMap().entries.map((entry) {
              final index = entry.key;
              final strategy = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(emotion.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(emotion.color),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        strategy,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Symptômes physiques
            const Text(
              'Symptômes physiques courants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emotion.physicalSymptoms.map((symptom) {
                return Chip(
                  label: Text(symptom),
                  backgroundColor: Colors.grey[100],
                  side: BorderSide(color: Colors.grey[300]!),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Émotions associées
            const Text(
              'Émotions associées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emotion.relatedEmotions.map((relatedEmotion) {
                return Chip(
                  label: Text(relatedEmotion),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                  labelStyle: const TextStyle(color: Colors.blue),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // Note d'encouragement
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 40,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Conseil bien-être',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emotion.isPositive
                        ? 'Profitez de cette émotion positive ! Partager votre joie avec d\'autres peut l\'amplifier et renforcer vos relations.'
                        : 'Prenez le temps de reconnaître et d\'accepter cette émotion. C\'est une partie normale de l\'expérience humaine.',
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
