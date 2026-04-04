import 'package:flutter/material.dart';

/// Widget to display audio waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color waveColor;
  final double lineWidth;

  WaveformPainter({
    required this.amplitudes,
    required this.waveColor,
    this.lineWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = size.width / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = amplitudes[i].clamp(0.1, 1.0);
      final height = (size.height / 2) * amplitude * 0.9;

      // Draw center line
      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.waveColor != waveColor;
  }
}

/// Widget displaying animated waveform
class WaveformVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final Color? waveColor;
  final double height;

  const WaveformVisualizer({
    Key? key,
    required this.amplitudes,
    this.waveColor,
    this.height = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = waveColor ?? Theme.of(context).primaryColor;

    return CustomPaint(
      painter: WaveformPainter(
        amplitudes: amplitudes,
        waveColor: color,
        lineWidth: 2.0,
      ),
      size: Size(double.infinity, height),
    );
  }
}
