// Liquid Glass controls with Petal's existing adaptive colors.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart' as sh;

enum _Variant { primary, outline, ghost, card, destructive, secondary }

class PetalButton extends ios.StatelessWidget {
  final ios.VoidCallback? onPressed;
  final ios.Widget child;
  final ios.Widget? leading;
  final ios.Widget? trailing;
  final ios.AlignmentGeometry alignment;
  final _Variant _variant;

  const PetalButton.primary({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.primary;
  const PetalButton.outline({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.outline;
  const PetalButton.ghost({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.ghost;
  const PetalButton.text({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.ghost;
  const PetalButton.link({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.ghost;
  const PetalButton.card({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.centerLeft})
    : _variant = _Variant.card;
  const PetalButton.secondary({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.secondary;
  const PetalButton.destructive({super.key, required this.child, this.onPressed,
    this.leading, this.trailing, this.alignment = ios.Alignment.center})
    : _variant = _Variant.destructive;

  @override
  ios.Widget build(ios.BuildContext context) {
    final colors = sh.Theme.of(context).colorScheme;
    final filled = _variant == _Variant.primary || _variant == _Variant.destructive;
    final foreground = _variant == _Variant.destructive
        ? colors.destructiveForeground
        : filled ? colors.primaryForeground
        : _variant == _Variant.ghost ? colors.primary : colors.foreground;
    final content = leading == null && trailing == null ? child : ios.Row(
      mainAxisSize: ios.MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const ios.SizedBox(width: 10)],
        if (_variant == _Variant.card) ios.Expanded(child: child) else ios.Flexible(child: child),
        if (trailing != null) ...[const ios.SizedBox(width: 10), trailing!],
      ],
    );
    final radius = _variant == _Variant.card ? 16.0 : 20.0;
    return glass.GlassButton.custom(
      onTap: onPressed ?? () {},
      enabled: onPressed != null,
      useOwnLayer: true,
      shape: glass.LiquidRoundedRectangle(borderRadius: radius),
      style: filled ? glass.GlassButtonStyle.prominent
          : _variant == _Variant.ghost ? glass.GlassButtonStyle.transparent
          : glass.GlassButtonStyle.filled,
      tintColor: _variant == _Variant.destructive ? colors.destructive
          : filled ? colors.primary : null,
      alignment: alignment,
      stretch: 0.15,
      child: ios.Padding(
        padding: const ios.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: ios.DefaultTextStyle.merge(
        style: ios.TextStyle(color: onPressed == null && _variant != _Variant.card ? colors.mutedForeground : foreground,
          fontSize: 15, fontWeight: ios.FontWeight.w500),
        child: ios.IconTheme.merge(
          data: ios.IconThemeData(color: onPressed == null ? colors.mutedForeground : foreground),
          child: content,
        ),
      ),
      ),
    );
  }
}

class PetalTextField extends ios.StatefulWidget {
  final ios.TextEditingController? controller;
  final ios.Widget? placeholder;
  final ios.ValueChanged<String>? onChanged;
  final ios.ValueChanged<String>? onSubmitted;
  final ios.VoidCallback? onEditingComplete;
  final bool obscureText;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final ios.TextInputType? keyboardType;
  final ios.FocusNode? focusNode;
  final ios.TextInputAction? textInputAction;
  final ios.TextStyle? style;
  const PetalTextField({super.key, this.controller, this.placeholder,
    this.onChanged, this.onSubmitted, this.onEditingComplete,
    this.obscureText = false, this.autofocus = false, this.enabled = true,
    this.maxLines = 1, this.maxLength, this.keyboardType, this.focusNode,
    this.textInputAction, this.style});
  @override
  ios.State<PetalTextField> createState() => _PetalTextFieldState();
}

class _PetalTextFieldState extends ios.State<PetalTextField> {
  bool _revealed = false;

  @override
  void didUpdateWidget(covariant PetalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller || oldWidget.obscureText != widget.obscureText) {
      _revealed = false;
    }
  }

  @override
  ios.Widget build(ios.BuildContext context) {
    final colors = sh.Theme.of(context).colorScheme;
    final hint = widget.placeholder is ios.Text ? (widget.placeholder as ios.Text).data : null;
    return glass.GlassTextField(
      controller: widget.controller, placeholder: hint,
      onChanged: widget.onChanged,
      onSubmitted: (value) {
        widget.onEditingComplete?.call();
        widget.onSubmitted?.call(value);
      },
      obscureText: widget.obscureText && !_revealed,
      autocorrect: !widget.obscureText,
      enableSuggestions: !widget.obscureText,
      autofocus: widget.autofocus, enabled: widget.enabled,
      maxLines: widget.maxLines ?? 1, maxLength: widget.maxLength,
      keyboardType: widget.keyboardType, focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      useOwnLayer: true,
      shape: const glass.LiquidRoundedRectangle(borderRadius: 14),
      suffixIcon: widget.obscureText
          ? ios.Icon(_revealed ? ios.CupertinoIcons.eye_slash : ios.CupertinoIcons.eye,
              color: colors.mutedForeground, size: 18)
          : widget.controller != null ? ios.Icon(ios.CupertinoIcons.clear_circled, color: colors.mutedForeground, size: 18) : null,
      suffixSemanticLabel: widget.obscureText ? (_revealed ? 'Hide password' : 'Show password') : 'Clear text',
      onSuffixTap: !widget.enabled ? null : widget.obscureText
          ? () => setState(() => _revealed = !_revealed)
          : widget.controller != null ? () {
              widget.controller!.clear();
              widget.onChanged?.call('');
            } : null,
      padding: const ios.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      textStyle: widget.style ?? ios.TextStyle(color: colors.foreground, fontSize: 15),
      placeholderStyle: ios.TextStyle(color: colors.mutedForeground, fontSize: 15),
    );
  }
}

class PetalSwitch extends ios.StatelessWidget {
  final bool value;
  final ios.ValueChanged<bool>? onChanged;
  const PetalSwitch({super.key, required this.value, required this.onChanged});
  @override
  ios.Widget build(ios.BuildContext context) => ios.Opacity(
    opacity: onChanged == null ? .5 : 1,
    child: ios.IgnorePointer(
      ignoring: onChanged == null,
      child: glass.GlassSwitch(
        value: value, onChanged: onChanged ?? (_) {},
        useOwnLayer: true,
        activeColor: sh.Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class PetalActivityIndicator extends ios.StatelessWidget {
  final double size;
  final ios.Color? color;
  final double? strokeWidth;
  const PetalActivityIndicator({super.key, this.size = 20, this.color, this.strokeWidth});
  @override
  ios.Widget build(ios.BuildContext context) => glass.GlassProgressIndicator.circular(
    size: size, strokeWidth: strokeWidth ?? 2.5, useOwnLayer: true, color: color ?? sh.Theme.of(context).colorScheme.mutedForeground,
  );
}
