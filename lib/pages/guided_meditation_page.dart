import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class GuidedMeditationPage extends StatefulWidget {
  const GuidedMeditationPage({super.key});

  @override
  State<GuidedMeditationPage> createState() => _GuidedMeditationPageState();
}

class _GuidedMeditationPageState extends State<GuidedMeditationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Timer? _timer;
  Duration _totalDuration = Duration(minutes: 10);
  Duration _elapsedTime = Duration.zero;
  Duration _remainingTime = Duration(minutes: 10);
  bool _isPlaying = false;
  int _currentStep = 0;
  double _volume = 0.8;
  bool _ambientSounds = true;
  String _selectedTheme = 'Sérénité';

  final List<MeditationStep> _steps = [
    MeditationStep(
      number: 1,
      title: 'PRÉPARATION',
      description:
          'Installez-vous confortablement\nPrenez quelques respirations profondes',
      duration: Duration(minutes: 1),
      color: Color(0xFF9575CD),
      icon: Icons.spa,
    ),
    MeditationStep(
      number: 2,
      title: 'CONCENTRATION',
      description:
          'Portez attention à votre respiration\nObservez l\'air qui entre et sort',
      duration: Duration(minutes: 3),
      color: Color(0xFF64B5F6),
      icon: Icons.psychology,
    ),
    MeditationStep(
      number: 3,
      title: 'OBSERVATION',
      description:
          'Observez vos pensées sans jugement\nLaissez-les passer comme des nuages',
      duration: Duration(minutes: 4),
      color: Color(0xFF81C784),
      icon: Icons.remove_red_eye,
    ),
    MeditationStep(
      number: 4,
      title: 'INTÉGRATION',
      description:
          'Revenez progressivement au présent\nPrenez conscience de votre corps',
      duration: Duration(minutes: 2),
      color: Color(0xFFFFB74D),
      icon: Icons.self_improvement,
    ),
  ];

  final List<String> _themes = [
    'Sérénité',
    'Concentration',
    'Sommeil',
    'Anti-stress',
    'Énergie',
  ];

  final List<Duration> _durations = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 20),
    Duration(minutes: 30),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: _totalDuration, vsync: this);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _elapsedTime = Duration(
            milliseconds: (_controller.value * _totalDuration.inMilliseconds)
                .toInt(),
          );
          _remainingTime = _totalDuration - _elapsedTime;
        });
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startMeditation() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _currentStep = 0;
    });

    _controller.forward();
    _startStepTimer();
  }

  void _startStepTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPlaying || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Vérifie si on doit passer à l'étape suivante
        final currentStepEndTime = _steps
            .sublist(0, _currentStep + 1)
            .fold(Duration.zero, (sum, step) => sum + step.duration);

        if (_elapsedTime >= currentStepEndTime &&
            _currentStep < _steps.length - 1) {
          _currentStep++;
        }

        // Si la méditation est terminée
        if (_elapsedTime >= _totalDuration) {
          _completeMeditation();
        }
      });
    });
  }

  void _pauseMeditation() {
    _timer?.cancel();
    _controller.stop();

    setState(() {
      _isPlaying = false;
    });
  }

  void _resumeMeditation() {
    _controller.forward();
    _startStepTimer();

    setState(() {
      _isPlaying = true;
    });
  }

  void _stopMeditation() {
    _timer?.cancel();
    _controller.stop();

    setState(() {
      _isPlaying = false;
      _elapsedTime = Duration.zero;
      _remainingTime = _totalDuration;
      _currentStep = 0;
      _controller.reset();
    });
  }

  void _completeMeditation() {
    _timer?.cancel();
    _controller.stop();

    setState(() {
      _isPlaying = false;
      _elapsedTime = _totalDuration;
      _remainingTime = Duration.zero;
      _currentStep = _steps.length - 1;
    });

    // Afficher un message de félicitations
    _showCompletionDialog();
  }

  void _changeDuration(Duration newDuration) {
    if (_isPlaying) {
      _pauseMeditation();
    }

    setState(() {
      _totalDuration = newDuration;
      _remainingTime = newDuration;
      _elapsedTime = Duration.zero;
      _controller.duration = newDuration;
      _controller.reset();
    });
  }

  void _toggleAmbientSounds() {
    setState(() {
      _ambientSounds = !_ambientSounds;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF81C784), size: 60),
            SizedBox(height: 16),
            Text(
              'Méditation terminée !',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Félicitations ! Vous avez complété ${_formatDuration(_totalDuration)} de méditation.\n\nPrenez un moment pour ressentir les bienfaits de cette pratique.',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 16,
            color: Color(0xFF5D6D7E),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continuer',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9575CD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return '$seconds seconde${seconds > 1 ? 's' : ''}';
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final currentStep = _steps[_currentStep];

    return Scaffold(
      backgroundColor: Color(0xFFF8FBFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isDesktop ? 200 : 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'MÉDITATION GUIDÉE',
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
                      Color(0xFF9575CD),
                      Color(0xFFB39DDB),
                      Color(0xFFD1C4E9),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 40, bottom: 20),
                    child: Opacity(
                      opacity: 0.7,
                      child: Lottie.asset(
                        'assets/lotties/meditation.json',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: Color(0xFF9575CD),
            elevation: 4,
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: _showSettings,
                tooltip: 'Paramètres',
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
                  // Carte principale
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
                        // Animation de méditation
                        Container(
                          height: isDesktop ? 300 : 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF9575CD).withOpacity(0.05),
                                Color(0xFF9575CD).withOpacity(0.02),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Lottie.asset(
                                'assets/lotties/meditation.json',
                                height: 180,
                                animate: _isPlaying,
                                fit: BoxFit.contain,
                              ),

                              // Overlay pour l'étape actuelle
                              Positioned(
                                bottom: 20,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentStep.color.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: currentStep.color.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        currentStep.icon,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        currentStep.title,
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contrôle principal et informations
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Timer circulaire
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: isDesktop ? 200 : 180,
                                    height: isDesktop ? 200 : 180,
                                    child: CircularProgressIndicator(
                                      value: _animation.value,
                                      strokeWidth: 10,
                                      backgroundColor: Colors.grey.shade100,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        currentStep.color,
                                      ),
                                    ),
                                  ),

                                  Column(
                                    children: [
                                      Text(
                                        _formatTime(_remainingTime),
                                        style: TextStyle(
                                          fontSize: isDesktop ? 42 : 36,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2C3E50),
                                          fontFamily: 'OpenSans',
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Temps restant',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontFamily: 'OpenSans',
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '${_formatTime(_elapsedTime)} / ${_formatTime(_totalDuration)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                          fontFamily: 'OpenSans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 24),

                              // Instructions
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: currentStep.color.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: currentStep.color.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Étape ${_currentStep + 1}/${_steps.length}',
                                      style: TextStyle(
                                        fontFamily: 'OpenSans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: currentStep.color,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      currentStep.description,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFF2C3E50),
                                        fontFamily: 'OpenSans',
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 32),

                              // Barre de progression des étapes
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progression de la séance',
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      Text(
                                        '${(_animation.value * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: currentStep.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: _animation.value,
                                    backgroundColor: Colors.grey.shade200,
                                    color: currentStep.color,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Début',
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Fin',
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                      children: [
                        // Boutons principaux
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Stop/Reset
                            _ControlButton(
                              icon: Icons.replay,
                              label: 'Réinitialiser',
                              color: Color(0xFF7DBBC3),
                              onPressed: _stopMeditation,
                            ),

                            SizedBox(width: 20),

                            // Play/Pause
                            GestureDetector(
                              onTap: () {
                                if (_isPlaying) {
                                  _pauseMeditation();
                                } else if (_elapsedTime.inSeconds > 0) {
                                  _resumeMeditation();
                                } else {
                                  _startMeditation();
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
                                    colors: _isPlaying
                                        ? [Color(0xFFFF5252), Color(0xFFFF4081)]
                                        : [
                                            Color(0xFF9575CD),
                                            Color(0xFFB39DDB),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isPlaying
                                                  ? Colors.red
                                                  : Colors.purple)
                                              .withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(width: 20),

                            // Sons ambiants
                            _ControlButton(
                              icon: _ambientSounds
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              label: _ambientSounds ? 'Sons ON' : 'Sons OFF',
                              color: Color(0xFF81C784),
                              onPressed: _toggleAmbientSounds,
                            ),
                          ],
                        ),

                        SizedBox(height: 24),

                        // Contrôle de volume
                        if (_ambientSounds)
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    Icons.volume_down,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Slider(
                                      value: _volume,
                                      onChanged: (value) {
                                        setState(() {
                                          _volume = value;
                                        });
                                      },
                                      min: 0.0,
                                      max: 1.0,
                                      divisions: 10,
                                      activeColor: Color(0xFF9575CD),
                                      inactiveColor: Colors.grey.shade300,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.volume_up,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Volume des sons ambiants',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Sélection de durée
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
                            Icon(Icons.timer, color: Color(0xFF9575CD)),
                            SizedBox(width: 12),
                            Text(
                              'DURÉE DE LA SÉANCE',
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _durations.map((duration) {
                            final isSelected = _totalDuration == duration;

                            return ChoiceChip(
                              label: Text(
                                '${duration.inMinutes} min',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  color: isSelected
                                      ? Colors.white
                                      : Color(0xFF9575CD),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => _changeDuration(duration),
                              backgroundColor: Colors.white,
                              selectedColor: Color(0xFF9575CD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Color(0xFF9575CD),
                                  width: 2,
                                ),
                              ),
                              elevation: isSelected ? 2 : 0,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Étapes de méditation
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
                            Icon(
                              Icons.stacked_line_chart,
                              color: Color(0xFF9575CD),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'ÉTAPES DE LA MÉDITATION',
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        ..._steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          final isActive = index == _currentStep;
                          final isCompleted = index < _currentStep;

                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? step.color.withOpacity(0.1)
                                  : isCompleted
                                  ? step.color.withOpacity(0.05)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? step.color.withOpacity(0.3)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: step.color.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? step.color
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isActive
                                          ? step.color
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : Text(
                                            step.number.toString(),
                                            style: TextStyle(
                                              color: isActive
                                                  ? step.color
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            step.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: step.color,
                                              fontFamily: 'OpenSans',
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          Text(
                                            '${step.duration.inMinutes} min',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                              fontFamily: 'OpenSans',
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 8),

                                      Text(
                                        step.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontFamily: 'OpenSans',
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
                          Color(0xFFF3E5F5),
                          Color(0xFFE8EAF6).withOpacity(0.7),
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
                              color: Color(0xFF9575CD),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'BIENFAITS DE LA MÉDITATION',
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop ? 4 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            final benefits = [
                              _BenefitItem(
                                icon: Icons.mood,
                                title: 'Réduction du stress',
                                description: '-30% de cortisol',
                                color: Color(0xFFE8F5E9),
                                iconColor: Color(0xFF4CAF50),
                              ),
                              _BenefitItem(
                                icon: Icons.psychology,
                                title: 'Clarté mentale',
                                description: 'Améliore la concentration',
                                color: Color(0xFFE3F2FD),
                                iconColor: Color(0xFF2196F3),
                              ),
                              _BenefitItem(
                                icon: Icons.nightlight_round,
                                title: 'Meilleur sommeil',
                                description: 'Qualité du sommeil +40%',
                                color: Color(0xFFF3E5F5),
                                iconColor: Color(0xFF9C27B0),
                              ),
                              _BenefitItem(
                                icon: Icons.favorite,
                                title: 'Santé cardiaque',
                                description: 'Baisse la tension artérielle',
                                color: Color(0xFFFFEBEE),
                                iconColor: Color(0xFFF44336),
                              ),
                            ];

                            final benefit = benefits[index];

                            return Container(
                              decoration: BoxDecoration(
                                color: benefit.color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    benefit.icon,
                                    color: benefit.iconColor,
                                    size: 28,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    benefit.title,
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    benefit.description,
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PARAMÈTRES',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Sélection du thème
              Text(
                'Thème de méditation',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),

              SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _themes.map((theme) {
                  final isSelected = _selectedTheme == theme;

                  return ChoiceChip(
                    label: Text(
                      theme,
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        color: isSelected ? Colors.white : Color(0xFF9575CD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedTheme = theme;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Color(0xFF9575CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Color(0xFF9575CD),
                        width: 1.5,
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 32),

              // Notification de rappel
              SwitchListTile(
                title: Text(
                  'Rappels quotidiens',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Recevez une notification pour méditer chaque jour',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.grey.shade600,
                  ),
                ),
                value: true,
                onChanged: (value) {},
                activeColor: Color(0xFF9575CD),
              ),

              SizedBox(height: 16),

              // Statistiques
              SwitchListTile(
                title: Text(
                  'Suivi des statistiques',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Enregistrez vos progrès et visualisez vos statistiques',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    color: Colors.grey.shade600,
                  ),
                ),
                value: true,
                onChanged: (value) {},
                activeColor: Color(0xFF9575CD),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class MeditationStep {
  final int number;
  final String title;
  final String description;
  final Duration duration;
  final Color color;
  final IconData icon;

  MeditationStep({
    required this.number,
    required this.title,
    required this.description,
    required this.duration,
    required this.color,
    required this.icon,
  });
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color iconColor;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.iconColor,
  });
}
