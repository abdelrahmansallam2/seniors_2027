import 'package:flutter/material.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';

class RetroImageReveal extends StatelessWidget {
  const RetroImageReveal({
    required this.image,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder = const SizedBox.shrink(),
    this.errorBuilder,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.color,
    this.colorBlendMode,
    super.key,
  });

  final ImageProvider image;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final Widget placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final bool gaplessPlayback;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final Color? color;
  final BlendMode? colorBlendMode;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = RetroMotion.reduceMotion(context);

    return Image(
      image: image,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      gaplessPlayback: gaplessPlayback,
      filterQuality: filterQuality,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      color: color,
      colorBlendMode: colorBlendMode,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return _ImageRevealFrame(
          frameReady: frame != null,
          wasSynchronouslyLoaded: wasSynchronouslyLoaded,
          gaplessPlayback: gaplessPlayback,
          duration: reduceMotion ? Duration.zero : RetroMotion.imageReveal,
          placeholder: placeholder,
          child: child,
        );
      },
      errorBuilder: errorBuilder ?? (context, error, stackTrace) => placeholder,
    );
  }
}

class _ImageRevealFrame extends StatefulWidget {
  const _ImageRevealFrame({
    required this.frameReady,
    required this.wasSynchronouslyLoaded,
    required this.gaplessPlayback,
    required this.duration,
    required this.placeholder,
    required this.child,
  });

  final bool frameReady;
  final bool wasSynchronouslyLoaded;
  final bool gaplessPlayback;
  final Duration duration;
  final Widget placeholder;
  final Widget child;

  @override
  State<_ImageRevealFrame> createState() => _ImageRevealFrameState();
}

class _ImageRevealFrameState extends State<_ImageRevealFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _hasDecodedFrame = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startIfReady();
  }

  @override
  void didUpdateWidget(covariant _ImageRevealFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!widget.frameReady && oldWidget.frameReady) {
      _started = false;
      _controller.value = 0;
      if (!widget.gaplessPlayback) _hasDecodedFrame = false;
    }
    _startIfReady();
    if (widget.frameReady && widget.duration == Duration.zero) {
      _controller.value = 1;
    }
  }

  void _startIfReady() {
    if (!widget.frameReady || _started) return;
    _started = true;
    final keepVisible = widget.gaplessPlayback && _hasDecodedFrame;
    _hasDecodedFrame = true;
    if (widget.wasSynchronouslyLoaded ||
        keepVisible ||
        widget.duration == Duration.zero) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.frameReady) {
      return widget.gaplessPlayback && _hasDecodedFrame
          ? widget.child
          : widget.placeholder;
    }
    if (widget.wasSynchronouslyLoaded) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: Curves.easeOutCubic.transform(_controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
