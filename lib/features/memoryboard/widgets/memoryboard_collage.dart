import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/motion/retro_motion.dart';
import 'package:seniors_27/features/memoryboard/data/memoryboard_image_cache.dart';
import 'package:seniors_27/features/memoryboard/memory_model.dart';

class MemoryboardCollage extends StatefulWidget {
  const MemoryboardCollage({
    required this.memories,
    required this.isActive,
    required this.onPhotoTap,
    this.imageProviderFor,
    this.onPhotosReady,
    super.key,
  }) : assert(memories.length <= 12);

  final List<Memory> memories;
  final bool isActive;
  final ValueChanged<Memory> onPhotoTap;
  final VoidCallback? onPhotosReady;

  @visibleForTesting
  final ImageProvider? Function(Memory memory)? imageProviderFor;

  static double heightForWidth(double width) => width * 1.72 + 28;

  @override
  State<MemoryboardCollage> createState() => _MemoryboardCollageState();
}

class _MemoryboardCollageState extends State<MemoryboardCollage> {
  static const _dropGap = Duration(milliseconds: 110);
  final Set<int> _ready = {};
  final Set<int> _released = {};
  Timer? _dropTimer;
  late List<int> _slots;
  late List<int> _dropOrder;
  late int _signature;
  int _generation = 0;
  bool _reduceMotion = false;
  bool _reportedReady = false;
  final Stopwatch _loadWatch = Stopwatch()..start();
  final MemoryboardImageCache _images = MemoryboardImageCache();

  int _contentSignature(List<Memory> memories) => Object.hashAll(
    memories.map((m) => Object.hash(m.id, m.imageUrl, m.name, m.date)),
  );

  void _configureLayout() {
    _signature = _contentSignature(widget.memories);
    var seed = 17;
    for (final memory in widget.memories) {
      for (final unit in '${memory.id}|${memory.imageUrl}'.codeUnits) {
        seed = (seed * 31 + unit) & 0x7fffffff;
      }
    }
    final random = math.Random(seed);
    _slots = [0, 1, 2, 3, 5, 6, 7, 8, 9, 10, 11]..shuffle(random);
    _slots.insert(0, 4);
    _dropOrder = List.generate(widget.memories.length, (index) => index);
    if (_dropOrder.length > 1) {
      final rest = _dropOrder.sublist(1)..shuffle(random);
      _dropOrder = [0, ...rest];
    }
  }

  @override
  void initState() {
    super.initState();
    _configureLayout();
    if (widget.isActive) {
      memoryboardTiming(
        'boardActive alreadyReady=0 total=${widget.memories.length}',
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = RetroMotion.reduceMotion(context);
    if (_reduceMotion) {
      _dropTimer?.cancel();
      _dropTimer = null;
      if (widget.isActive) _released.addAll(_ready);
    }
  }

  @override
  void didUpdateWidget(covariant MemoryboardCollage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature != _contentSignature(widget.memories) ||
        oldWidget.imageProviderFor != widget.imageProviderFor) {
      _dropTimer?.cancel();
      _dropTimer = null;
      _ready.clear();
      _released.clear();
      _generation++;
      _reportedReady = false;
      _loadWatch.reset();
      _configureLayout();
    }
    if (!widget.isActive) {
      _dropTimer?.cancel();
      _dropTimer = null;
    } else {
      if (!oldWidget.isActive) {
        _released.clear();
        _reportedReady = false;
        _loadWatch.reset();
        memoryboardTiming(
          'boardActive alreadyReady=${_ready.length} total=${widget.memories.length}',
        );
      }
      _reportBoardReady();
      _scheduleDrop();
    }
  }

  void _photoReady(int index, int generation) {
    if (!mounted || generation != _generation || !_ready.add(index)) return;
    if (_ready.length == 1 || _ready.length == widget.memories.length) {
      memoryboardTiming(
        'readyPhotos=${_ready.length}/${widget.memories.length} elapsedMs=${_loadWatch.elapsedMilliseconds}',
      );
    }
    _reportBoardReady();
    if (_reduceMotion && widget.isActive) {
      setState(() => _released.add(index));
    } else {
      _scheduleDrop();
    }
  }

  void _reportBoardReady() {
    if (!widget.isActive ||
        _reportedReady ||
        _ready.length != widget.memories.length) {
      return;
    }
    _reportedReady = true;
    memoryboardTiming(
      'boardReady photos=${_ready.length} elapsedMs=${_loadWatch.elapsedMilliseconds}',
    );
    widget.onPhotosReady?.call();
  }

  void _scheduleDrop() {
    if (!widget.isActive || _dropTimer != null) return;
    if (_reduceMotion) {
      _released.addAll(_ready);
      return;
    }
    // Batch same-frame image completions so cached photos keep a varied order.
    _dropTimer = Timer(const Duration(milliseconds: 16), _releaseNext);
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _releaseNext() {
    _dropTimer = null;
    if (!mounted || !widget.isActive) return;
    final waiting = _dropOrder.where(
      (index) => _ready.contains(index) && !_released.contains(index),
    );
    if (waiting.isEmpty) return;
    setState(() => _released.add(waiting.first));
    // Keep the minimum gap even when the next image finishes a little later.
    _dropTimer = Timer(_dropGap, _releaseNext);
  }

  @override
  void dispose() {
    _dropTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final generation = _generation;
        return Stack(
          key: const ValueKey('memoryboard_collage'),
          clipBehavior: Clip.hardEdge,
          children: [
            for (var index = 0; index < widget.memories.length; index++)
              _buildPhoto(index, size, generation),
          ],
        );
      },
    );
  }

  Widget _buildPhoto(int index, Size size, int generation) {
    final memory = widget.memories[index];
    final identity = memory.id.isNotEmpty
        ? memory.id
        : '${index}_${memory.imageUrl ?? ''}';
    final random = math.Random(_slots[index] * 97 + _slots.first + 41);
    final width = size.width * (0.24 + random.nextDouble() * 0.05);
    final height = width / 0.72;
    final rotation = (random.nextDouble() - 0.5) * 0.32;
    final rotatedWidth =
        width * math.cos(rotation).abs() + height * math.sin(rotation).abs();
    final rotatedHeight =
        height * math.cos(rotation).abs() + width * math.sin(rotation).abs();
    const margin = 13.0;
    final column = _slots[index] % 3;
    const anchors = [
      Offset(0.19, 0.13),
      Offset(0.53, 0.14),
      Offset(0.82, 0.12),
      Offset(0.17, 0.39),
      Offset(0.51, 0.44),
      Offset(0.83, 0.36),
      Offset(0.20, 0.65),
      Offset(0.54, 0.67),
      Offset(0.82, 0.63),
      Offset(0.17, 0.88),
      Offset(0.50, 0.89),
      Offset(0.81, 0.87),
    ];
    final anchor = anchors[_slots[index]];
    final centerX =
        (size.width * anchor.dx +
                (random.nextDouble() - 0.5) * size.width * 0.025)
            .clamp(
              margin + rotatedWidth / 2,
              size.width - margin - rotatedWidth / 2,
            );
    final centerY =
        (size.height * anchor.dy + (random.nextDouble() - 0.5) * height * 0.12)
            .clamp(
              margin + rotatedHeight / 2,
              size.height - margin - rotatedHeight / 2,
            );
    final top = centerY - height / 2;
    final image =
        widget.imageProviderFor?.call(memory) ?? _images.imageFor(memory);

    return Positioned(
      key: ValueKey('memory_placement_$identity'),
      left: centerX - width / 2,
      top: top,
      width: width,
      height: height,
      child: _PhotoDrop(
        key: ValueKey('memory_drop_${generation}_$identity'),
        shown: _released.contains(index),
        rotation: rotation,
        fallDistance: top + height + 24,
        drift: (column - 1) * 14,
        child: Semantics(
          button: true,
          label: memory.name.isEmpty
              ? 'Open memory photo'
              : 'Open memory by ${memory.name}',
          child: GestureDetector(
            key: ValueKey('memory_$identity'),
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onPhotoTap(memory),
            child: RepaintBoundary(
              child: _PolaroidCard(
                memory: memory,
                image: image,
                onReady: () => _photoReady(index, generation),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoDrop extends StatefulWidget {
  const _PhotoDrop({
    required this.shown,
    required this.rotation,
    required this.fallDistance,
    required this.drift,
    required this.child,
    super.key,
  });

  final bool shown;
  final double rotation;
  final double fallDistance;
  final double drift;
  final Widget child;

  @override
  State<_PhotoDrop> createState() => _PhotoDropState();
}

class _PhotoDropState extends State<_PhotoDrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  void _syncAnimation() {
    if (!widget.shown) {
      _controller.value = 0;
    } else if (RetroMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _PhotoDrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final progress = _controller.value;
      final descent = Curves.easeOutCubic.transform(progress);
      final settle = progress < 0.78
          ? 0.0
          : -3 * math.sin(math.pi * (progress - 0.78) / 0.22);
      return ExcludeSemantics(
        excluding: !_controller.isCompleted,
        child: IgnorePointer(
          ignoring: !_controller.isCompleted,
          child: Opacity(
            key: ValueKey('memory_drop_opacity_${widget.key}'),
            opacity: (progress / 0.22).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(
                widget.drift * (1 - descent),
                -widget.fallDistance * (1 - descent) + settle,
              ),
              child: Transform.rotate(
                angle:
                    widget.rotation +
                    (1 - descent) * (widget.rotation < 0 ? -0.12 : 0.12),
                child: Transform.scale(
                  scale: 0.96 + 0.04 * descent,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PolaroidCard extends StatefulWidget {
  const _PolaroidCard({
    required this.memory,
    required this.image,
    required this.onReady,
  });

  final Memory memory;
  final ImageProvider? image;
  final VoidCallback onReady;

  @override
  State<_PolaroidCard> createState() => _PolaroidCardState();
}

class _PolaroidCardState extends State<_PolaroidCard> {
  bool _readyReported = false;

  void _reportReady() {
    if (_readyReported) return;
    _readyReported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady();
    });
  }

  Widget _placeholder() {
    const colors = [
      AppColors.cyan,
      AppColors.green,
      AppColors.pink,
      AppColors.yellowWarm,
      AppColors.paper,
    ];
    return ColoredBox(
      color: colors[widget.memory.id.hashCode % colors.length],
      child: const SizedBox.expand(),
    );
  }

  Widget _photo() {
    if (widget.image == null) {
      _reportReady();
      return _placeholder();
    }
    return Image(
      image: widget.image!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) _reportReady();
        return frame == null ? _placeholder() : child;
      },
      errorBuilder: (context, error, stackTrace) {
        _reportReady();
        return _placeholder();
      },
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: _photo(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.memory.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.memory.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Positioned(
        top: -3,
        left: 16,
        child: Container(
          width: 20,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.yellowWarm.withValues(alpha: 0.7),
            border: Border.all(color: AppColors.ink, width: 0.5),
          ),
        ),
      ),
    ],
  );
}
