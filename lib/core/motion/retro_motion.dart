import 'package:flutter/widgets.dart';

abstract final class RetroMotion {
  static const Duration pageForward = Duration(milliseconds: 320);
  static const Duration pageReverse = Duration(milliseconds: 280);
  static const double pageSlide = 0.04;

  static const Duration tab = Duration(milliseconds: 180);
  static const double tabOffset = 8;
  static const double tabMinOpacity = 0.9;

  static const Duration card = Duration(milliseconds: 260);
  static const Duration imageReveal = Duration(milliseconds: 180);
  static const Duration overlay = Duration(milliseconds: 220);

  static const int staggerStepMs = 40;
  static const int maxStaggerMs = 200;

  static const Offset entranceOffset = Offset(0, 10);
  static const double entranceScale = 0.97;

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  static Duration staggerDelay(int index) {
    if (index <= 0) return Duration.zero;
    final milliseconds = (index * staggerStepMs).clamp(0, maxStaggerMs);
    return Duration(milliseconds: milliseconds);
  }
}
