import 'package:flutter/material.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';

class RetroEntrance extends StatefulWidget {
  const RetroEntrance({
    required this.child,
    this.delay = Duration.zero,
    this.duration = RetroMotion.card,
    this.offset = RetroMotion.entranceOffset,
    this.scale = RetroMotion.entranceScale,
    this.curve = Curves.easeOutCubic,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double scale;
  final Curve curve;

  @override
  State<RetroEntrance> createState() => _RetroEntranceState();
}

class _RetroEntranceState extends State<RetroEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  late final Animation<double> _opacity;
  late final Animation<Offset> _translation;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    final duration = total == Duration.zero
        ? const Duration(milliseconds: 1)
        : total;
    final start = widget.delay.inMicroseconds / duration.inMicroseconds;

    _controller = AnimationController(vsync: this, duration: duration);
    _curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: widget.curve),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(_curved);
    _translation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(_curved);
    _scale = Tween<double>(begin: widget.scale, end: 1).animate(_curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (RetroMotion.reduceMotion(context)) {
      _started = true;
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _translation.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
