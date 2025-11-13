import 'dart:math' as math;
import 'package:flutter/material.dart';
class BarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final double height;
  const BarChart({
    super.key,
    required this.data,
    required this.labels,
    this.height = 220,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          data: data,
          labels: labels,
          axisColor: Theme.of(context).colorScheme.onSurfaceVariant,
          barColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color axisColor;
  final Color barColor;
  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.axisColor,
    required this.barColor,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.reduce(math.max);
    final barW = size.width / (data.length * 1.8);
    final gap = barW * 0.8;
    final axisPaint = Paint()
      ..color = axisColor.withOpacity(0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 28),
      Offset(size.width, size.height - 28),
      axisPaint,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < data.length; i++) {
      final x = i * (barW + gap) + gap / 2;
      final h = ((data[i] / maxV) * (size.height - 48)).clamp(0.0, size.height);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - 28 - h, barW, h),
        const Radius.circular(6),
      );
      final barPaint = Paint()..color = barColor.withOpacity(0.9);
      canvas.drawRRect(rect, barPaint);
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(fontSize: 11, color: axisColor),
      );
      textPainter.layout(minWidth: 0, maxWidth: barW + gap);
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width - barW) / 2, size.height - 24),
      );
    }
  }
  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.labels != labels ||
      oldDelegate.barColor != barColor ||
      oldDelegate.axisColor != axisColor;
}