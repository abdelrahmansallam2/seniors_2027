import 'package:flutter/material.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';

Future<T?> showRetroOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Close',
  Color barrierColor = Colors.black54,
  RouteSettings? routeSettings,
  bool useRootNavigator = true,
}) {
  final reduceMotion = RetroMotion.reduceMotion(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: reduceMotion ? Duration.zero : RetroMotion.overlay,
    routeSettings: routeSettings,
    useRootNavigator: useRootNavigator,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return _RetroOverlayTransition(
        animation: animation,
        reduceMotion: reduceMotion,
        child: child,
      );
    },
  );
}

class _RetroOverlayTransition extends StatefulWidget {
  const _RetroOverlayTransition({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_RetroOverlayTransition> createState() =>
      _RetroOverlayTransitionState();
}

class _RetroOverlayTransitionState extends State<_RetroOverlayTransition> {
  late CurvedAnimation _curved;

  CurvedAnimation _curve(Animation<double> parent) => CurvedAnimation(
    parent: parent,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _curved = _curve(widget.animation);
  }

  @override
  void didUpdateWidget(covariant _RetroOverlayTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved.dispose();
      _curved = _curve(widget.animation);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion || RetroMotion.reduceMotion(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(_curved),
        child: widget.child,
      ),
    );
  }
}
