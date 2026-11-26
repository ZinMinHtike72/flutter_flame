import "dart:math" as math;
import "package:flutter/material.dart";

/// One-shot spring entrance, halo and drawn check; reduced motion shows the final mark.
class AppSuccessMark extends StatelessWidget {
  const AppSuccessMark({required this.color, super.key, this.size = 132});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 1200),
        builder: (context, value, child) => Transform.scale(
          scale: reduced
              ? 1
              : Curves.easeOutBack.transform((value / 0.6).clamp(0, 1)),
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _SuccessMarkPainter(
                color: color,
                foreground: Theme.of(context).colorScheme.surface,
                progress: reduced ? 1 : value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessMarkPainter extends CustomPainter {
  const _SuccessMarkPainter({
    required this.color,
    required this.foreground,
    required this.progress,
  });
  final Color color;
  final Color foreground;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.29;
    canvas.drawCircle(
      center,
      radius * 1.58,
      Paint()..color = color.withValues(alpha: 0.05),
    );
    canvas.drawCircle(
      center,
      radius * 1.25,
      Paint()..color = color.withValues(alpha: 0.09),
    );
    final burst = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
    for (final index in List.generate(10, (index) => index)) {
      final angle = index * math.pi / 5;
      final offset =
          Offset(math.cos(angle), math.sin(angle)) *
          radius *
          (1.3 + burst * 0.35);
      canvas.drawCircle(
        center + offset,
        2.3 * (1 - burst),
        Paint()..color = color.withValues(alpha: (1 - burst) * 0.65),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = color);
    final check = Path()
      ..moveTo(center.dx - radius * 0.43, center.dy)
      ..lineTo(center.dx - radius * 0.1, center.dy + radius * 0.3)
      ..lineTo(center.dx + radius * 0.47, center.dy - radius * 0.32);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(
        0,
        metric.length * ((progress - 0.25) / 0.5).clamp(0, 1),
      ),
      Paint()
        ..color = foreground
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SuccessMarkPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.foreground != foreground ||
      oldDelegate.progress != progress;
}
