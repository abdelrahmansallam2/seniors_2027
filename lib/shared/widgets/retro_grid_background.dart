import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class RetroGridBackground extends StatelessWidget {
  const RetroGridBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: CustomPaint(painter: const _RetroGridPainter(), child: child),
    );
  }
}

class _RetroGridPainter extends CustomPainter {
  const _RetroGridPainter();

  static const spacing = 27.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RetroGridPainter oldDelegate) => false;
}
