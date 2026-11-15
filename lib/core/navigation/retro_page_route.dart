import 'package:flutter/material.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';

class RetroPageRoute<T> extends PageRouteBuilder<T> {
  RetroPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog = false,
    super.maintainState = true,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: RetroMotion.pageForward,
         reverseTransitionDuration: RetroMotion.pageReverse,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return _RetroPageTransition(
             animation: animation,
             secondaryAnimation: secondaryAnimation,
             child: child,
           );
         },
       );
}

class _RetroPageTransition extends StatefulWidget {
  const _RetroPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_RetroPageTransition> createState() => _RetroPageTransitionState();
}

class _RetroPageTransitionState extends State<_RetroPageTransition> {
  late CurvedAnimation _incoming;
  late CurvedAnimation _outgoing;

  CurvedAnimation _curve(Animation<double> parent) => CurvedAnimation(
    parent: parent,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _incoming = _curve(widget.animation);
    _outgoing = _curve(widget.secondaryAnimation);
  }

  @override
  void didUpdateWidget(covariant _RetroPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _incoming.dispose();
      _incoming = _curve(widget.animation);
    }
    if (oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _outgoing.dispose();
      _outgoing = _curve(widget.secondaryAnimation);
    }
  }

  @override
  void dispose() {
    _incoming.dispose();
    _outgoing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (RetroMotion.reduceMotion(context)) return widget.child;

    return FadeTransition(
      opacity: _incoming,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(RetroMotion.pageSlide, 0),
          end: Offset.zero,
        ).animate(_incoming),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.94).animate(_outgoing),
          child: widget.child,
        ),
      ),
    );
  }
}
