import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnergyIndicator extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final Color color;
  final String unit;

  const EnergyIndicator({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.color,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C1A3F),
                  fontFamily: 'OpenSans',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}$unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 40,
            child: SfLinearGauge(
              minimum: 0,
              maximum: maxValue,
              interval: maxValue / 5,
              showTicks: false,
              showLabels: false,
              // CORRECTION ICI : Utilisez LinearAxis au lieu de SfLinearTrackStyle
              axisTrackStyle: const LinearAxisTrackStyle(
                thickness: 8,
                color: Color(0xFFF0F0F0),
                edgeStyle: LinearEdgeStyle.bothCurve,
              ),
              barPointers: [
                LinearBarPointer(
                  value: value,
                  thickness: 8,
                  color: color,
                  edgeStyle: LinearEdgeStyle.bothCurve,
                ),
              ],
              markerPointers: [
                LinearShapePointer(
                  value: value,
                  height: 16,
                  width: 16,
                  color: color,
                  borderColor: Colors.white,
                  borderWidth: 2,
                  shapeType: LinearShapePointerType.circle,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontFamily: 'OpenSans',
                ),
              ),
              Text(
                '${maxValue.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, duration: 300.ms);
  }
}

// Widget pour indicateur circulaire
class CircularEnergyIndicator extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color primaryColor;
  final Color secondaryColor;

  const CircularEnergyIndicator({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.primaryColor,
    this.secondaryColor = const Color(0xFFF0F0F0),
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / maxValue * 100).clamp(0, 100);

    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [primaryColor.withOpacity(0.1), Colors.transparent],
          stops: const [0.5, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de fond
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              backgroundColor: secondaryColor,
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
          ),

          // Cercle de progression
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: value / maxValue,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Valeur au centre
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'OpenSans',
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6D5D82),
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
