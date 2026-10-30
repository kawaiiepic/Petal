import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ArrowButton extends StatefulWidget {
  final bool visible;
  final IconData icon;
  final VoidCallback onPressed;

  const ArrowButton({
    super.key,
    required this.visible,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
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
                color: Colors.black.withValues(alpha: _hovered ? 0.65 : 0.45),
                shape: BoxShape.circle,
                boxShadow: [
                  if (_hovered)
                    const BoxShadow(blurRadius: 8, color: Colors.black),
                ],
              ),
              child: Button.text(
                onPressed: widget.onPressed,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(widget.icon, size: 25, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
