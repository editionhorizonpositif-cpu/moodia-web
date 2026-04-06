import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class VisualizationPage extends StatefulWidget {
  const VisualizationPage({super.key});

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;
  bool _isPlaying = false;

  final List<VisualizationStep> _steps = [
    VisualizationStep(
      title: 'Préparation',
      description: 'Installez-vous confortablement et fermez les yeux',
      duration: 30,
      color: Color(0xFFFFB6C1),
    ),
    VisualizationStep(
      title: 'Détente',
      description: 'Relâchez chaque partie de votre corps',
      duration: 45,
      color: Color(0xFF9575CD),
    ),
    VisualizationStep(
      title: 'Visualisation',
      description: 'Imaginez votre objectif atteint',
      duration: 60,
      color: Color(0xFF7DBBC3),
    ),
    VisualizationStep(
      title: 'Émotions',
      description: 'Sentez les émotions positives',
      duration: 45,
      color: Color(0xFF81C784),
    ),
    VisualizationStep(
      title: 'Retour',
      description: 'Revenez progressivement au présent',
      duration: 30,
      color: Color(0xFFFFD54F),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _steps[_currentStep].duration),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.forward();
        _controller.addStatusListener((status) {
          if (status == AnimationStatus.completed && _isPlaying) {
            if (_currentStep < _steps.length - 1) {
              _nextStep();
            } else {
              _stopSession();
            }
          }
        });
      } else {
        _controller.stop();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _controller.duration = Duration(seconds: _steps[_currentStep].duration);
        _controller.forward(from: 0);
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _controller.duration = Duration(seconds: _steps[_currentStep].duration);
        _controller.forward(from: 0);
      });
    }
  }

  void _stopSession() {
    setState(() {
      _isPlaying = false;
      _currentStep = 0;
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visualisation Positive',
          style: TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
        ),
        backgroundColor: const Color(0xFFFFB6C1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFF8FBFC),
        child: Column(
          children: [
            // Progression
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: Colors.grey.shade200,
                    color: currentStep.color,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Étape ${_currentStep + 1} sur ${_steps.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5D6D7E),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Animation
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: currentStep.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          'assets/lotties/visualization.json',
                          height: 150,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Étape actuelle
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: currentStep.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: currentStep.color, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            currentStep.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: currentStep.color,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${currentStep.duration} secondes',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF7DBBC3),
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            currentStep.description,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF2C3E50),
                              fontFamily: 'OpenSans',
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Timer circulaire
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: _controller.value,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    currentStep.color,
                                  ),
                                ),
                              ),
                              Text(
                                '${(currentStep.duration - (_controller.value * currentStep.duration)).toInt()}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Description détaillée
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instructions détaillées',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Suivez ces instructions pour une visualisation efficace:\n\n'
                              '1. Trouvez un endroit calme et confortable\n'
                              '2. Fermez les yeux et respirez profondément\n'
                              '3. Laissez votre imagination créer l\'image souhaitée\n'
                              '4. Engagez tous vos sens dans la visualisation\n'
                              '5. Ressentez les émotions comme si c\'était réel\n'
                              '6. Revenez progressivement au moment présent',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5D6D7E),
                                fontFamily: 'OpenSans',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Toutes les étapes
                    const Text(
                      'Parcours de visualisation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'OpenSans',
                      ),
                    ),

                    const SizedBox(height: 15),

                    ..._steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: index == _currentStep
                              ? step.color.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: index == _currentStep
                                ? step.color
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: step.color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: step.color,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  Text(
                                    '${step.duration} secondes',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF7DBBC3),
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  Text(
                                    step.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5D6D7E),
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index < _currentStep)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 30),

                    // Bienfaits
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienfaits de la visualisation',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '• Réduit le stress et l\'anxiété\n'
                              '• Améliore la confiance en soi\n'
                              '• Augmente la motivation\n'
                              '• Développe la créativité\n'
                              '• Aide à atteindre les objectifs\n'
                              '• Améliore les performances\n'
                              '• Favorise la pensée positive',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF5D6D7E),
                                fontFamily: 'OpenSans',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contrôles
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _previousStep,
                    icon: const Icon(Icons.skip_previous, size: 30),
                    color: _currentStep > 0
                        ? const Color(0xFF7DBBC3)
                        : Colors.grey,
                  ),
                  ElevatedButton(
                    onPressed: _togglePlay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFB6C1),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.skip_next, size: 30),
                    color: _currentStep < _steps.length - 1
                        ? const Color(0xFF7DBBC3)
                        : Colors.grey,
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

class VisualizationStep {
  final String title;
  final String description;
  final int duration;
  final Color color;

  VisualizationStep({
    required this.title,
    required this.description,
    required this.duration,
    required this.color,
  });
}
