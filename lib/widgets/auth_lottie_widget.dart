// lib/widgets/auth_lottie_widget.dart - VERSION SIMPLIFIÉE CORRIGÉE
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import '../services/lottie_service.dart';

class AuthLottieWidget extends StatefulWidget {
  final int assetId;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool autoPlay;
  final bool repeat;
  final bool reverse;
  final VoidCallback? onLoaded;
  final VoidCallback? onError;
  final Color? backgroundColor;

  const AuthLottieWidget({
    super.key,
    required this.assetId,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.autoPlay = true,
    this.repeat = true,
    this.reverse = false,
    this.onLoaded,
    this.onError,
    this.backgroundColor,
  });

  @override
  State<AuthLottieWidget> createState() => _AuthLottieWidgetState();
}

class _AuthLottieWidgetState extends State<AuthLottieWidget>
    with SingleTickerProviderStateMixin {
  late final LottieService _lottieService;
  LottieComposition? _composition;
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, String>? _headers;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _lottieService = LottieService(ApiService());
    _loadLottie();

    if (widget.autoPlay) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadLottie() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      if (kDebugMode) {
        await _lottieService.debugLottieUrl(widget.assetId);
      }

      _headers = await _lottieService.getLottieHeaders();
      final url = _lottieService.getLottieStreamUrl(widget.assetId);

      if (kDebugMode) {
        print('🎬 Chargement Lottie avec headers depuis: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final composition = await LottieComposition.fromBytes(
          response.bodyBytes,
        );

        if (mounted) {
          setState(() {
            _composition = composition;
            _isLoading = false;
          });

          if (widget.autoPlay && _animationController != null) {
            _animationController!.repeat(reverse: widget.reverse);
          }

          widget.onLoaded?.call();
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erreur chargement Lottie: $e');
        print('📚 Stack trace: $stackTrace');
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        widget.onError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor ?? Colors.grey.shade100,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    if (_hasError || _composition == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor ?? Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.animation,
              size: widget.width != null ? widget.width! * 0.3 : 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Animation non disponible',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // CORRECTION: Suppression des paramètres 'progress' et 'controller' externes
    // On utilise notre propre contrôleur interne pour l'animation
    return Lottie(
      composition: _composition!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: widget.repeat,
      reverse: widget.reverse,
      animate: widget.autoPlay,
      controller: _animationController,
    );
  }
}
