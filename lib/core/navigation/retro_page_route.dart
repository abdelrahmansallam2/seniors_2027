import 'package:flutter/material.dart';

class RetroPageRoute<T> extends PageRouteBuilder<T> {
  RetroPageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final incoming = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );
          final outgoing = CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(incoming),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.045, 0),
                end: Offset.zero,
              ).animate(incoming),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.94).animate(outgoing),
                child: child,
              ),
            ),
          );
        },
      );
}
