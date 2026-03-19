import 'package:flutter/material.dart';

class ScrollableWidget extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  const ScrollableWidget({super.key, required this.child, required this.controller});

  @override
  State<StatefulWidget> createState() => _ScrollableWidget();
}

class _ScrollableWidget extends State<ScrollableWidget> {
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  bool _isHovering = false;

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;

    _controller.addListener(_updateArrows);
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;

    final pos = _controller.position;

    setState(() {
      _canScrollLeft = pos.pixels > 0;
      _canScrollRight = pos.pixels < pos.maxScrollExtent;
    });
  }

  void _scrollBy(double offset) {
    _controller.animateTo(_controller.offset + offset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Stack(
        children: [
          widget.child,

          Positioned(
            left: 8,
            top: 0,
            bottom: 0,

            child: Center(
              child: ArrowButton(visible: _isHovering && _canScrollLeft, icon: Icons.arrow_back_ios_new, onPressed: () => _scrollBy(-900)),
            ),
          ),

          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: ArrowButton(visible: _isHovering && _canScrollRight, icon: Icons.arrow_forward_ios, onPressed: () => _scrollBy(900)),
            ),
          ),
        ],
      ),
    );
  }
}

class ArrowButton extends StatefulWidget {
  final bool visible;
  final IconData icon;
  final VoidCallback onPressed;

  const ArrowButton({super.key, required this.visible, required this.icon, required this.onPressed});

  @override
  State<ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _hovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_hovered ? 0.65 : 0.45),
                shape: BoxShape.circle,
                boxShadow: [if (_hovered) const BoxShadow(blurRadius: 8, color: Colors.black26)],
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox(width: 36, height: 36, child: Icon(widget.icon, size: 18, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
