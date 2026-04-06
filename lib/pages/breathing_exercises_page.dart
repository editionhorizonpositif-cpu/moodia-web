import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class BreathingExercisesPage extends StatefulWidget {
  const BreathingExercisesPage({super.key});

  @override
  State<BreathingExercisesPage> createState() => _BreathingExercisesPageState();
}

class _BreathingExercisesPageState extends State<BreathingExercisesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  Timer? _timer;

  int _currentPhase =
      0; // 0: inspiration, 1: rétention, 2: expiration, 3: pause
  int _cycleCount = 0;
  bool _isActive = false;
  int _remainingSeconds = 4;
  double _progress = 0.0;
  bool _showGuideLines = true;

  // État pour gérer les transitions
  bool _isTransitioning = false;

  final List<BreathingPhase> _phases = [
    BreathingPhase(
      name: 'INSPIRATION',
      duration: 4,
      instruction: 'Inspirez profondément par le nez\nRemplissez vos poumons',
      color: Color(0xFF64B5F6),
      icon: Icons.inbox,
    ),
    BreathingPhase(
      name: 'RÉTENTION',
      duration: 7,
      instruction: 'Retenez votre souffle\nMaintenez doucement',
      color: Color(0xFF9575CD),
      icon: Icons.pause,
    ),
    BreathingPhase(
      name: 'EXPIRATION',
      duration: 8,
      instruction: 'Expirez lentement par la bouche\nVidez complètement',
      color: Color(0xFF81C784),
      icon: Icons.outbox,
    ),
    BreathingPhase(
      name: 'PAUSE',
      duration: 2,
      instruction: 'Pause naturelle\nLaissez votre corps se réguler',
      color: Color(0xFF90A4AE),
      icon: Icons.hourglass_empty,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      duration: Duration(seconds: _phases[0].duration),
      vsync: this,
    );

    _breathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Réinitialise les valeurs
    _resetToInitialState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _resetToInitialState() {
    _remainingSeconds = _phases[0].duration;
    _progress = 0.0;
    _breathController.value = 0.0;
  }

  void _startBreathing() {
    if (_isActive) return;

    setState(() {
      _isActive = true;
      _cycleCount = _cycleCount == 0 ? 1 : _cycleCount;
    });

    _startCurrentPhase();
  }

  void _startCurrentPhase() {
    if (!_isActive || _isTransitioning) return;

    final phase = _phases[_currentPhase];

    // Configure l'animation
    _breathController.duration = Duration(seconds: phase.duration);

    // Démarre l'animation selon la phase
    if (_currentPhase == 0) {
      // Inspiration: animation forward
      _breathController.forward(from: 0.0);
    } else if (_currentPhase == 1) {
      // Rétention: animation maintenue
      _breathController.value = 1.0;
    } else if (_currentPhase == 2) {
      // Expiration: animation reverse
      _breathController.reverse(from: 1.0);
    } else {
      // Pause: animation au début
      _breathController.value = 0.0;
    }

    // Démarre le compte à rebours
    _startCountdown();
  }

  void _startCountdown() {
    // Annule tout timer existant
    _timer?.cancel();

    // Réinitialise le compte à rebours
    _remainingSeconds = _phases[_currentPhase].duration;
    _progress = 0.0;

    // Démarre le timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isActive || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          // Calcule la progression (0.0 à 1.0)
          final totalDuration = _phases[_currentPhase].duration;
          _progress = 1.0 - (_remainingSeconds / totalDuration);

          // Met à jour la valeur de l'animation
          if (_currentPhase == 0) {
            // Inspiration: forward progress
            _breathController.value = _progress;
          } else if (_currentPhase == 2) {
            // Expiration: reverse progress
            _breathController.value = 1.0 - _progress;
          }
        }

        // Quand le temps est écoulé
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _goToNextPhase();
        }
      });
    });
  }

  void _goToNextPhase() {
    if (!_isActive || !mounted) return;

    setState(() {
      _isTransitioning = true;

      // Passe à la phase suivante
      _currentPhase = (_currentPhase + 1) % _phases.length;

      // Incrémente le cycle quand on revient à l'inspiration
      if (_currentPhase == 0) {
        _cycleCount++;
      }

      _isTransitioning = false;

      // Démarre la nouvelle phase
      if (_isActive) {
        _startCurrentPhase();
      }
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    _breathController.stop();

    setState(() {
      _isActive = false;
    });
  }

  void _pauseBreathing() {
    if (!_isActive) return;

    _timer?.cancel();
    _breathController.stop();

    setState(() {
      _isActive = false;
    });
  }

  void _resumeBreathing() {
    if (_isActive) return;

    setState(() {
      _isActive = true;
    });

    _startCurrentPhase();
  }

  void _resetBreathing() {
    _timer?.cancel();
    _breathController.stop();

    setState(() {
      _isActive = false;
      _currentPhase = 0;
      _cycleCount = 0;
      _resetToInitialState();
    });
  }

  void _toggleGuideLines() {
    setState(() {
      _showGuideLines = !_showGuideLines;
    });
  }

  void _skipToPhase(int phaseIndex) {
    if (phaseIndex < 0 || phaseIndex >= _phases.length) return;

    _timer?.cancel();

    setState(() {
      _currentPhase = phaseIndex;
      _resetToInitialState();

      // Si l'exercice était actif, on redémarre
      if (_isActive) {
        _startCurrentPhase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhase];
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Color(0xFFF8FBFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isDesktop ? 180 : 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'RESPIRATION 4-7-8',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4FC3F7),
                      Color(0xFF64B5F6),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 30,
                      top: 60,
                      child: Icon(
                        Icons.waves,
                        size: 80,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: Color(0xFF4FC3F7),
            elevation: 4,
            actions: [
              IconButton(
                icon: Icon(
                  _showGuideLines ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _toggleGuideLines,
                tooltip: _showGuideLines ? 'Cacher guide' : 'Afficher guide',
              ),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: 24,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Section principale
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Cercle de respiration
                        Container(
                          height: isDesktop ? 400 : 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                currentPhase.color.withOpacity(0.05),
                                currentPhase.color.withOpacity(0.02),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cercle extérieur
                              AnimatedBuilder(
                                animation: _breathAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 200 + (_breathAnimation.value * 80),
                                    height: 200 + (_breathAnimation.value * 80),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: currentPhase.color.withOpacity(
                                          0.3,
                                        ),
                                        width: 3,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Cercle principal animé
                              AnimatedBuilder(
                                animation: _breathAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 160 + (_breathAnimation.value * 60),
                                    height: 160 + (_breathAnimation.value * 60),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          currentPhase.color.withOpacity(0.8),
                                          currentPhase.color.withOpacity(0.2),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: currentPhase.color.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // Contenu central
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: Duration(milliseconds: 300),
                                      child: Text(
                                        '$_remainingSeconds',
                                        key: ValueKey(_remainingSeconds),
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: currentPhase.color,
                                          fontFamily: 'OpenSans',
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'secondes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Lignes de guide (optionnel)
                              if (_showGuideLines)
                                CustomPaint(
                                  painter: _BreathingGuidePainter(
                                    progress: _progress,
                                    phaseColor: currentPhase.color,
                                  ),
                                  size: Size(300, 300),
                                ),
                            ],
                          ),
                        ),

                        // Informations de phase
                        Container(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Nom de phase et cycle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentPhase.name,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: currentPhase.color,
                                          fontFamily: 'OpenSans',
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Cycle $_cycleCount',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'OpenSans',
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Progression
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentPhase.color.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentPhase + 1}/4',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: currentPhase.color,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),

                              // Instruction
                              Text(
                                currentPhase.instruction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade800,
                                  fontFamily: 'OpenSans',
                                  height: 1.5,
                                ),
                              ),

                              SizedBox(height: 24),

                              // Barre de progression
                              LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.grey.shade200,
                                color: currentPhase.color,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Contrôles
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.08),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Boutons principaux
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reset
                            _ControlButton(
                              icon: Icons.replay,
                              label: 'Réinitialiser',
                              color: Color(0xFF7DBBC3),
                              onPressed: _resetBreathing,
                            ),

                            SizedBox(width: 16),

                            // Play/Pause
                            GestureDetector(
                              onTap: () {
                                if (_isActive) {
                                  _pauseBreathing();
                                } else if (_cycleCount > 0) {
                                  _resumeBreathing();
                                } else {
                                  _startBreathing();
                                }
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isActive
                                        ? [Color(0xFFFF5252), Color(0xFFFF4081)]
                                        : [
                                            Color(0xFF4FC3F7),
                                            Color(0xFF64B5F6),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isActive ? Colors.red : Colors.blue)
                                              .withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isActive
                                      ? Icons.pause
                                      : (_cycleCount > 0
                                            ? Icons.play_arrow
                                            : Icons.play_arrow_rounded),
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(width: 16),

                            // Guide
                            _ControlButton(
                              icon: Icons.info_outline,
                              label: 'Guide',
                              color: Color(0xFF9575CD),
                              onPressed: _toggleGuideLines,
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Indicateur d'état
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _isActive
                                ? Color(0xFFE8F5E9)
                                : Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isActive
                                  ? Color(0xFF81C784).withOpacity(0.3)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isActive
                                    ? Icons.waves
                                    : Icons.pause_circle_outline,
                                size: 20,
                                color: _isActive
                                    ? Color(0xFF4CAF50)
                                    : Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isActive ? 'Respiration active' : 'En pause',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontWeight: FontWeight.w600,
                                  color: _isActive
                                      ? Color(0xFF4CAF50)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Boutons de navigation rapide
                        if (!_isActive)
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _phases.asMap().entries.map((entry) {
                              final index = entry.key;
                              final phase = entry.value;

                              return ElevatedButton(
                                onPressed: () => _skipToPhase(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: index == _currentPhase
                                      ? phase.color
                                      : phase.color.withOpacity(0.1),
                                  foregroundColor: index == _currentPhase
                                      ? Colors.white
                                      : phase.color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  '${phase.name} (${phase.duration}s)',
                                  style: TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Phases de respiration
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.08),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer, color: Color(0xFF64B5F6)),
                            SizedBox(width: 12),
                            Text(
                              'SÉQUENCE 4-7-8',
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Grille des phases
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop ? 4 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isDesktop ? 1.2 : 1.4,
                              ),
                          itemCount: _phases.length,
                          itemBuilder: (context, index) {
                            final phase = _phases[index];
                            final isActive = index == _currentPhase;

                            return GestureDetector(
                              onTap: () => _skipToPhase(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? phase.color.withOpacity(0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? phase.color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: phase.color.withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: phase.color,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            phase.icon,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 12),

                                      Text(
                                        '${phase.duration}s',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: phase.color,
                                          fontFamily: 'OpenSans',
                                        ),
                                      ),

                                      SizedBox(height: 8),

                                      Text(
                                        phase.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                          fontFamily: 'OpenSans',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Section bienfaits
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE3F2FD),
                          Color(0xFFF3E5F5).withOpacity(0.5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.withOpacity(0.08),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: Color(0xFF81C784),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'BIENFAITS SCIENTIFIQUES',
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _BenefitCard(
                              icon: Icons.mood,
                              title: 'Réduction du stress',
                              description: 'Diminue le cortisol de 25%',
                              color: Color(0xFFE8F5E9),
                              iconColor: Color(0xFF4CAF50),
                            ),
                            _BenefitCard(
                              icon: Icons.nightlight_round,
                              title: 'Amélioration du sommeil',
                              description: 'Favorise l\'endormissement',
                              color: Color(0xFFF3E5F5),
                              iconColor: Color(0xFF9C27B0),
                            ),
                            _BenefitCard(
                              icon: Icons.heart_broken,
                              title: 'Santé cardiaque',
                              description: 'Baisse la tension artérielle',
                              color: Color(0xFFFFEBEE),
                              iconColor: Color(0xFFF44336),
                            ),
                            _BenefitCard(
                              icon: Icons.psychology,
                              title: 'Clarté mentale',
                              description: 'Améliore la concentration',
                              color: Color(0xFFE3F2FD),
                              iconColor: Color(0xFF2196F3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BreathingPhase {
  final String name;
  final int duration;
  final String instruction;
  final Color color;
  final IconData icon;

  BreathingPhase({
    required this.name,
    required this.duration,
    required this.instruction,
    required this.color,
    required this.icon,
  });
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: IconButton(
            icon: Icon(icon, size: 24, color: color),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color iconColor;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingGuidePainter extends CustomPainter {
  final double progress;
  final Color phaseColor;

  _BreathingGuidePainter({required this.progress, required this.phaseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 150.0;

    final paint = Paint()
      ..color = phaseColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dessine les lignes de guide
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Dessine le cercle de progression
    final progressPaint = Paint()
      ..color = phaseColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -pi / 2,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingGuidePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        phaseColor != oldDelegate.phaseColor;
  }
}
