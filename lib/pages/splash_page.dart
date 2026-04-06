import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:moodia/routes/route.dart';
import 'package:moodia/services/auth_service.dart';
import 'package:moodia/services/user_cache_service.dart';
import 'package:provider/provider.dart';

class MoodiaSplashPage extends StatefulWidget {
  const MoodiaSplashPage({super.key});

  @override
  State<MoodiaSplashPage> createState() => _MoodiaSplashPageState();
}

class _MoodiaSplashPageState extends State<MoodiaSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particlesController;
  late AnimationController _waveController;
  late AnimationController _lotusController;
  late AnimationController _loadingController;
  late AnimationController _dotsController;

  late Animation<double> _logoScale;
  late Animation<double> _outerRingRotation;
  late Animation<double> _innerRingRotation;
  late Animation<double> _glowOpacity;
  late Animation<double> _loadingProgress;

  final List<Particle> _particles = [];
  final List<Wave> _waves = [];

  bool _initializationComplete = false;
  String? _targetRoute;

  @override
  void initState() {
    super.initState();
    _initParticlesAndWaves();
    _initAnimations();
    _initializeApp(); // lance la vérification en arrière-plan
  }

  void _initParticlesAndWaves() {
    for (int i = 0; i < 30; i++) {
      _particles.add(
        Particle(
          position: Offset(
            math.Random().nextDouble() * 400 - 200,
            math.Random().nextDouble() * 800 - 400,
          ),
          velocity: Offset(
            math.Random().nextDouble() * 0.5 - 0.25,
            math.Random().nextDouble() * 0.5 - 0.25,
          ),
          size: math.Random().nextDouble() * 6 + 2,
          opacity: math.Random().nextDouble() * 0.5 + 0.2,
        ),
      );
    }

    for (int i = 0; i < 3; i++) {
      _waves.add(
        Wave(offset: i * 20.0, amplitude: 15.0 + i * 5, speed: 0.02 + i * 0.01),
      );
    }
  }

  void _initAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _lotusController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 0.9,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_logoController);

    _outerRingRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _innerRingRotation = Tween<double>(begin: 0, end: -2 * math.pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _glowOpacity = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _loadingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _loadingController.forward();
  }

  Future<void> _initializeApp() async {
    final authService = context.read<AuthService>();
    final userCache = context.read<UserCacheService>();

    try {
      // 1. Vérifier le cache local
      final isCached = await userCache.isUserCached();
      if (isCached) {
        final user = await userCache.loadCachedUser();
        if (user != null) {
          authService.setUserFromCache(user);
          if (!user.emailVerified) {
            _targetRoute = '/verify-email';
          } else {
            _targetRoute = AppRoutes.home;
          }
          _finishInitialization();
          return;
        }
      }

      // 2. Vérifier la session active (token valide)
      if (authService.isAuthenticated && authService.currentUser != null) {
        final user = authService.currentUser!;
        if (!user.emailVerified) {
          _targetRoute = '/verify-email';
        } else {
          _targetRoute = AppRoutes.home;
        }
        _finishInitialization();
        return;
      }

      // 3. Sinon, aller vers la connexion
      _targetRoute = AppRoutes.login;
      _finishInitialization();
    } catch (e) {
      // En cas d'erreur, on va vers la connexion
      _targetRoute = AppRoutes.login;
      _finishInitialization();
    }
  }

  void _finishInitialization() {
    if (_initializationComplete) return;
    _initializationComplete = true;

    // On attend que la barre de progression atteigne 100% (si pas déjà finie)
    if (_loadingController.isAnimating) {
      _loadingController.forward().then((_) {
        _navigate();
      });
    } else {
      _navigate();
    }
  }

  void _navigate() {
    if (!mounted) return;
    // Petit délai pour laisser le temps à l'utilisateur de voir le 100%
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, _targetRoute!);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particlesController.dispose();
    _waveController.dispose();
    _lotusController.dispose();
    _loadingController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _particlesController,
        _waveController,
        _lotusController,
        _loadingController,
        _dotsController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                const Color(0xFF7DBBC3),
                const Color(0xFF5CA8B0),
                const Color(0xFF8B9DC3).withOpacity(0.9),
                const Color(0xFF7DBBC3).withOpacity(0.8),
              ],
              stops: const [0.0, 0.4, 0.8, 1.0],
            ),
          ),
          child: Stack(
            children: [
              ..._buildParticles(),
              _buildLotusFlower(),
              _buildSerenityWaves(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnimatedLogo(),
                    const SizedBox(height: 60),
                    _buildAnimatedTitle(),
                    const SizedBox(height: 20),
                    _buildSlogan(),
                    const SizedBox(height: 80),
                    _buildProgressBar(),
                    const SizedBox(height: 20),
                    _buildLoadingText(),
                  ],
                ),
              ),
              _buildCircularEnergy(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      particle.position = Offset(
        particle.position.dx + particle.velocity.dx,
        particle.position.dy + particle.velocity.dy,
      );
      if (particle.position.dx.abs() > 300) {
        particle.velocity = Offset(-particle.velocity.dx, particle.velocity.dy);
      }
      if (particle.position.dy.abs() > 400) {
        particle.velocity = Offset(particle.velocity.dx, -particle.velocity.dy);
      }
      final shimmer =
          (math.sin(
                        _particlesController.value * 2 * math.pi +
                            particle.position.dx,
                      ) *
                      0.2 +
                  0.8)
              .clamp(0.3, 1.0);
      return Positioned(
        left:
            MediaQuery.of(context).size.width / 2 + particle.position.dx - 200,
        top:
            MediaQuery.of(context).size.height / 2 + particle.position.dy - 300,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(particle.opacity * shimmer),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3 * shimmer),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLotusFlower() {
    return Positioned(
      right: 50,
      bottom: 100,
      child: Transform.scale(
        scale: 1.5,
        child: Opacity(
          opacity: 0.15,
          child: CustomPaint(
            size: const Size(150, 150),
            painter: LotusPainter(progress: _lotusController.value),
          ),
        ),
      ),
    );
  }

  Widget _buildSerenityWaves() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SerenityWavePainter(
          waves: _waves,
          progress: _waveController.value,
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Transform.scale(
      scale: _logoScale.value,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFF9A826,
                  ).withOpacity(_glowOpacity.value * 0.3),
                  blurRadius: 60,
                  spreadRadius: 30,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(_glowOpacity.value * 0.5),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: _outerRingRotation.value,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2.5,
                ),
              ),
              child: CustomPaint(
                painter: RingDotsPainter(
                  color: const Color(0xFFFFB6C1),
                  count: 12,
                  progress: _outerRingRotation.value,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: _innerRingRotation.value,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CustomPaint(
                painter: RingDotsPainter(
                  color: const Color(0xFF7DBBC3),
                  count: 8,
                  progress: _innerRingRotation.value,
                  dotSize: 4,
                ),
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFFF0F8FF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.self_improvement,
                  size: 70,
                  color: const Color(0xFF7DBBC3).withOpacity(0.9),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9A826),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9A826).withOpacity(0.8),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(16, (index) {
            final angle = (index * 22.5) * math.pi / 180;
            final distance = 100.0;
            final pulse =
                math.sin(_logoController.value * 2 * math.pi + index) * 0.3 +
                0.7;
            return Positioned(
              left: 70 + math.cos(angle) * distance,
              top: 70 + math.sin(angle) * distance,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8 * pulse),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5 * pulse),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    const title = 'MOODIA';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: title.split('').asMap().entries.map((entry) {
        final index = entry.key;
        final letter = entry.value;
        final delay = index * 100;
        final letterAnimation = CurvedAnimation(
          parent: _logoController,
          curve: Interval(
            delay / 2000,
            (delay + 400) / 2000,
            curve: Curves.elasticOut,
          ),
        );
        return AnimatedBuilder(
          animation: letterAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - letterAnimation.value) * 30),
              child: Opacity(
                opacity: letterAnimation.value,
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Playfair Display',
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 15,
                        offset: Offset(3, 3),
                      ),
                      Shadow(color: Color(0x4DFFFFFF), blurRadius: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSlogan() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: const Text(
              'Votre compagnon bien-être',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
                fontFamily: 'OpenSans',
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Container(
          width: 260,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _loadingProgress.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFB6C1),
                        Colors.white,
                        Color(0xFF7DBBC3),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${(_loadingProgress.value * 100).toInt()}%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18,
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 5),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chargement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  math.sin(_dotsController.value * 2 * math.pi + index) * 4,
                ),
                child: const Text(
                  '.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildCircularEnergy() {
    return Positioned.fill(
      child: CustomPaint(
        painter: CircularEnergyPainter(progress: _logoController.value),
      ),
    );
  }
}

// --- Classes et painters (inchangés) ---
class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  });
}

class Wave {
  double offset;
  double amplitude;
  double speed;
  Wave({required this.offset, required this.amplitude, required this.speed});
}

class RingDotsPainter extends CustomPainter {
  final Color color;
  final int count;
  final double progress;
  final double dotSize;
  RingDotsPainter({
    required this.color,
    required this.count,
    required this.progress,
    this.dotSize = 3,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) + progress;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final pulse = math.sin(progress * 2 + i) * 0.5 + 0.5;
      canvas.drawCircle(
        Offset(x, y),
        dotSize * (0.8 + pulse * 0.4),
        paint..color = color.withOpacity(0.6 + pulse * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LotusPainter extends CustomPainter {
  final double progress;
  LotusPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi / 8) + progress * 0.5;
      final petalScale = 0.6 + math.sin(progress * 2 * math.pi + i) * 0.2;
      final path = Path();
      final startX = center.dx + 30 * math.cos(angle);
      final startY = center.dy + 30 * math.sin(angle);
      path.moveTo(startX, startY);
      for (double t = 0; t <= 1; t += 0.1) {
        final r = 40 * (1 - t) * petalScale;
        final x = center.dx + r * math.cos(angle + t * math.pi * 0.5);
        final y = center.dy + r * math.sin(angle + t * math.pi * 0.5);
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        paint
          ..color = Colors.white.withOpacity(
            0.3 + math.sin(progress + i) * 0.1,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SerenityWavePainter extends CustomPainter {
  final List<Wave> waves;
  final double progress;
  SerenityWavePainter({required this.waves, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < waves.length; i++) {
      final wave = waves[i];
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.1 - i * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final path = Path();
      path.moveTo(0, size.height / 2 + wave.offset);
      for (double x = 0; x <= size.width; x += 10) {
        final y =
            size.height / 2 +
            wave.offset +
            wave.amplitude *
                math.sin((x / 100) * 2 * math.pi + progress * wave.speed * 100);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularEnergyPainter extends CustomPainter {
  final double progress;
  CircularEnergyPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 3; i++) {
      final radius = 100.0 + i * 40 + math.sin(progress * 2 * math.pi + i) * 10;
      paint.color = Colors.white.withOpacity(0.1 - i * 0.03);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
