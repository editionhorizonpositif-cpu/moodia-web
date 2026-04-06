import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class MindfulWalkPage extends StatefulWidget {
  const MindfulWalkPage({super.key});

  @override
  State<MindfulWalkPage> createState() => _MindfulWalkPageState();
}

class _MindfulWalkPageState extends State<MindfulWalkPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isWalking = false;
  int _seconds = 0;
  Timer? _timer;
  int _playCount = 0;
  double _progress = 0.0;
  final int _totalDuration = 598; // 9:58 minutes en secondes

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudioTwice() async {
    _playCount = 0;

    Future<void> playOnce() async {
      await _audioPlayer.play(AssetSource('sounds/mindful_walk.mp3'));
    }

    _audioPlayer.onPlayerComplete.listen((_) async {
      _playCount++;
      if (_playCount < 2 && _isWalking) {
        await playOnce();
      } else {
        _stopMindfulWalk();
      }
    });

    await playOnce();
  }

  void _startMindfulWalk() async {
    setState(() {
      _isWalking = true;
      _seconds = 0;
      _progress = 0.0;
    });

    await _playAudioTwice();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _progress = _seconds / _totalDuration;
        if (_seconds >= _totalDuration) {
          _stopMindfulWalk();
        }
      });
    });
  }

  void _stopMindfulWalk() async {
    setState(() {
      _isWalking = false;
    });
    await _audioPlayer.stop();
    _timer?.cancel();
  }

  void _pauseMindfulWalk() async {
    setState(() {
      _isWalking = false;
    });
    await _audioPlayer.pause();
    _timer?.cancel();
  }

  void _resumeMindfulWalk() async {
    setState(() {
      _isWalking = true;
    });
    await _audioPlayer.resume();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _progress = _seconds / _totalDuration;
        if (_seconds >= _totalDuration) {
          _stopMindfulWalk();
        }
      });
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isDesktop ? 200 : 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Balade Consciente',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.teal.shade700,
                      Colors.teal.shade400,
                      Colors.teal.shade300,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: isDesktop ? 60 : 20),
                    child: Opacity(
                      opacity: 0.8,
                      child: Lottie.asset(
                        'assets/lotties/walking.json',
                        width: isDesktop ? 120 : 100,
                        animate: _isWalking,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.teal.shade600,
            elevation: 4,
            shadowColor: Colors.teal.shade200.withOpacity(0.3),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 16,
              vertical: 24,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte principale
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Animation principale
                        Container(
                          height: isDesktop ? 300 : 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.teal.shade50,
                                Colors.teal.shade100.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Lottie.asset(
                              'assets/lotties/walking.json',
                              width: isDesktop ? 280 : 200,
                              animate: _isWalking,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Citation
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.teal.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.self_improvement,
                                color: Colors.teal.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "« Ressens chaque pas, écoute chaque souffle. »",
                                  style: TextStyle(
                                    fontFamily: 'OpenSans',
                                    fontSize: isDesktop ? 18 : 16,
                                    color: Colors.teal.shade800,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Timer et progression
                        Column(
                          children: [
                            Text(
                              _isWalking
                                  ? "Marche en cours..."
                                  : "Prêt pour une marche consciente ?",
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                fontSize: isDesktop ? 20 : 18,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Carte timer
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.teal.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _formatTime(_seconds),
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: isDesktop ? 48 : 42,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.teal.shade800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Barre de progression
                                  LinearProgressIndicator(
                                    value: _progress,
                                    backgroundColor: Colors.teal.shade100,
                                    color: Colors.teal.shade400,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "0:00",
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          color: Colors.teal.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "9:58",
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          color: Colors.teal.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Contrôles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Bouton Stop/Arrêter
                            if (_isWalking)
                              ElevatedButton(
                                onPressed: _stopMindfulWalk,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 32 : 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.red.shade200,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stop, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Arrêter",
                                      style: TextStyle(
                                        fontFamily: 'OpenSans',
                                        fontSize: isDesktop ? 16 : 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Bouton Play/Démarrer ou Pause/Reprendre
                            if (!_isWalking || _seconds > 0)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: _isWalking ? 16 : 0,
                                ),
                                child: ElevatedButton(
                                  onPressed: _seconds > 0 && !_isWalking
                                      ? _resumeMindfulWalk
                                      : _startMindfulWalk,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade500,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 32 : 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    shadowColor: Colors.teal.shade200,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _seconds > 0 && !_isWalking
                                            ? Icons.play_arrow
                                            : Icons.play_arrow_rounded,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _seconds > 0 && !_isWalking
                                            ? "Reprendre"
                                            : "Démarrer la balade",
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: isDesktop ? 16 : 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Bouton Pause
                            if (_isWalking && _seconds > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: ElevatedButton(
                                  onPressed: _pauseMindfulWalk,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade400,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDesktop ? 32 : 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    shadowColor: Colors.orange.shade200,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.pause, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Pause",
                                        style: TextStyle(
                                          fontFamily: 'OpenSans',
                                          fontSize: isDesktop ? 16 : 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Indicateur d'astuce
                        if (_isWalking)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Concentrez-vous sur les sensations de vos pas, "
                                    "votre respiration et l'environnement autour de vous.",
                                    style: TextStyle(
                                      fontFamily: 'OpenSans',
                                      fontSize: isDesktop ? 15 : 14,
                                      color: Colors.blue.shade800,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section des bienfaits (uniquement sur desktop ou en mode paysage)
                  if (isDesktop)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bienfaits de la marche consciente",
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildBenefitCard(
                                Icons.psychology,
                                "Réduction du stress",
                                "Diminue le cortisol et améliore la clarté mentale",
                                Colors.purple.shade50,
                                Colors.purple.shade600,
                              ),
                              _buildBenefitCard(
                                Icons.favorite_border,
                                "Santé cardiaque",
                                "Améliore la circulation et baisse la tension",
                                Colors.red.shade50,
                                Colors.red.shade600,
                              ),
                              _buildBenefitCard(
                                Icons.nights_stay,
                                "Meilleur sommeil",
                                "Favorise un sommeil plus profond et réparateur",
                                Colors.indigo.shade50,
                                Colors.indigo.shade600,
                              ),
                              _buildBenefitCard(
                                Icons.mood,
                                "Bien-être mental",
                                "Augmente la production d'endorphines",
                                Colors.orange.shade50,
                                Colors.orange.shade600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Instructions (version mobile ou réduite)
                  if (!isDesktop)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Instructions",
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "1. Trouvez un endroit calme et sécurisé\n"
                            "2. Lancez la session audio guidée\n"
                            "3. Marchez à votre rythme en étant présent à chaque instant\n"
                            "4. Concentrez-vous sur votre respiration et vos sensations\n"
                            "5. Terminez par une minute de gratitude",
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
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

  Widget _buildBenefitCard(
    IconData icon,
    String title,
    String description,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
