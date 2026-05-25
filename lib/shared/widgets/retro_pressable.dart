import 'package:flutter/material.dart';

typedef RetroPressableBuilder =
    Widget Function(BuildContext context, bool isHovered, bool isPressed);

class RetroPressable extends StatefulWidget {
  const RetroPressable({required this.builder, required this.onTap, super.key});

  final RetroPressableBuilder builder;
  final VoidCallback? onTap;

  @override
  State<RetroPressable> createState() => _RetroPressableState();
}

class _RetroPressableState extends State<RetroPressable> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => widget.onTap != null;

  void _setHovered(bool hovered) {
    if (!_isEnabled || _isHovered == hovered) {
      return;
    }
    setState(() => _isHovered = hovered);
  }

  void _setPressed(bool pressed) {
    if (!_isEnabled || _isPressed == pressed) {
      return;
    }
    setState(() => _isPressed = pressed);
  }

  @override
  void didUpdateWidget(covariant RetroPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEnabled && (_isHovered || _isPressed)) {
      _isHovered = false;
      _isPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: _isEnabled ? (_) => _setHovered(true) : null,
      onExit: _isEnabled ? (_) => _setHovered(false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: _isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: _isEnabled ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: widget.builder(context, _isHovered, _isPressed),
      ),
    );
  }
}
