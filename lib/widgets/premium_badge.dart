// widgets/premium_badge.dart
import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final double size;
  final bool animated;

  const PremiumBadge({Key? key, this.size = 24, this.animated = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!animated) {
      return Container(
        padding: EdgeInsets.all(size * 0.15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: size * 0.5,
              spreadRadius: size * 0.1,
            ),
          ],
        ),
        child: Icon(
          Icons.workspace_premium,
          color: Colors.white,
          size: size * 0.7,
        ),
      );
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: EdgeInsets.all(size * 0.15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              blurRadius: size * 0.5,
              spreadRadius: size * 0.1,
            ),
          ],
        ),
        child: Icon(
          Icons.workspace_premium,
          color: Colors.white,
          size: size * 0.7,
        ),
      ),
    );
  }
}
