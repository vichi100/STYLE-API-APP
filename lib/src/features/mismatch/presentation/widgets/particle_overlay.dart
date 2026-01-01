import 'dart:math';
import 'package:flutter/material.dart';

class ParticleMismatchOverlay extends StatefulWidget {
  final AnimationController controller;
  final List<Rect> sourceRects;
  final Color backgroundColor;

  const ParticleMismatchOverlay({
    super.key,
    required this.controller,
    required this.sourceRects,
    required this.backgroundColor,
  });

  @override
  State<ParticleMismatchOverlay> createState() => _ParticleMismatchOverlayState();
}

class _ParticleMismatchOverlayState extends State<ParticleMismatchOverlay> {
  late List<Particle> _particles;
  late Offset _mergeTarget;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _mergeTarget = _calculateMergeTarget();
  }

  Offset _calculateMergeTarget() {
    if (widget.sourceRects.isEmpty) return Offset.zero;
    double sumX = 0;
    double sumY = 0;
    for (final rect in widget.sourceRects) {
      sumX += rect.center.dx;
      sumY += rect.center.dy;
    }
    // Centroid of all image centers
    return Offset(sumX / widget.sourceRects.length, sumY / widget.sourceRects.length);
  }

  List<Particle> _generateParticles() {
    final rand = Random();
    final List<Particle> particles = [];
    final colors = [
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.white,
      Colors.pinkAccent,
    ];

    for (final rect in widget.sourceRects) {
      // Density: ~400 particles per image for "more dense" cloud
      for (int i = 0; i < 400; i++) {
        final color = colors[rand.nextInt(colors.length)];
        
        // Random point inside the rect
        final startX = rect.left + rand.nextDouble() * rect.width;
        final startY = rect.top + rand.nextDouble() * rect.height;
        final startPos = Offset(startX, startY);

        particles.add(Particle(
          color: color,
          startPos: startPos,
          // Hover offset: random jitter for cloud effect
          hoverOffset: Offset(rand.nextDouble() - 0.5, rand.nextDouble() - 0.5) * 40,
          speed: 0.2 + rand.nextDouble() * 0.5, 
          size: 2.0 + rand.nextDouble() * 3.0,
          randomPhase: rand.nextDouble() * 2 * pi, // For independent hover movement
        ));
      }
    }
    return particles;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticleMismatchPainter(
            particles: _particles,
            mergeTarget: _mergeTarget,
            progress: widget.controller.value,
            backgroundColor: widget.backgroundColor,
            sourceRects: widget.sourceRects,
          ),
        );
      },
    );
  }
}

class ParticleMismatchPainter extends CustomPainter {
  final List<Particle> particles;
  final Offset mergeTarget;
  final double progress;

  final List<Rect> sourceRects;
  final Color backgroundColor;

  ParticleMismatchPainter({
    required this.particles, 
    required this.mergeTarget, 
    required this.progress,
    required this.sourceRects,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Mask the original images
    final maskPaint = Paint()..color = backgroundColor;
    for (final rect in sourceRects) {
      canvas.drawRect(rect, maskPaint);
    }

    // 2. Draw Particles
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      Offset pos;
      double opacity = 1.0;

      if (progress < 0.3) {
        // Phase 1: CLOUD HOVER (0.0 - 0.3)
        // Particles dissolve from image and float locally
        final t = progress / 0.3;
        final easeT = Curves.easeOutCubic.transform(t);
        
        // Expand from perfect image grid to "cloud" state
        // Add some sine wave motion for "floating"
        final floatX = sin(progress * 10 + p.randomPhase) * 5;
        final floatY = cos(progress * 8 + p.randomPhase) * 5;
        
        pos = p.startPos + (p.hoverOffset * easeT) + Offset(floatX, floatY);
        
      } else {
        // Phase 2: SLOW MERGE (0.3 - 1.0)
        // Clouds drift towards the center (mergeTarget)
        final t = (progress - 0.3) / 0.7;
        final easeT = Curves.easeInOutSine.transform(t); // Gentle movement
        
        // Calculate the "Hovered" position (start of this phase)
        // We use t=1.0 state of phase 1 + float at current time
        // Actually, just maintain the offset relative to the moving center
        
        final floatX = sin(progress * 10 + p.randomPhase) * 5;
        final floatY = cos(progress * 8 + p.randomPhase) * 5;
        final currentCloudPos = p.startPos + p.hoverOffset + Offset(floatX, floatY);
        
        // Lerp the entire cloud towards the target
        // But we want them to blend, so lerp towards target + some noise
        // targetPos is simply the mergeTarget (+ noise to keep it cloud-like at center)
        final targetPos = mergeTarget + (p.hoverOffset * 0.5); // Contract slightly at center
        
        pos = Offset.lerp(currentCloudPos, targetPos, easeT)!;
      }

      paint.color = p.color.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(pos, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final Color color;
  final Offset startPos;
  final Offset hoverOffset;
  final double speed;
  final double size;
  final double randomPhase;

  Particle({
    required this.color,
    required this.startPos,
    required this.hoverOffset,
    required this.speed,
    required this.size,
    required this.randomPhase,
  });
}
