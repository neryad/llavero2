import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo PIN con puntos exactos, auto-envío y sacudida al error.
///
/// El `TextField` real es invisible (solo captura el teclado); encima se
/// dibujan [length] puntos. No hay contador «n/8».
class PinCodeInput extends StatefulWidget {
  const PinCodeInput({
    super.key,
    required this.length,
    required this.onCompleted,
    this.error,
    this.autoFocus = true,
    this.semanticLabel,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final String? error;
  final bool autoFocus;
  final String? semanticLabel;

  @override
  State<PinCodeInput> createState() => _PinCodeInputState();
}

class _PinCodeInputState extends State<PinCodeInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late Animation<double> _offset;
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    _offset = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_shake);
  }

  @override
  void didUpdateWidget(PinCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null &&
        widget.error != _lastError &&
        widget.error!.isNotEmpty) {
      _controller.clear();
      _shake.forward(from: 0);
    }
    _lastError = widget.error ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _changed(String value) {
    if (value.length < widget.length) return;
    final pin = value;
    _controller.clear();
    widget.onCompleted(pin);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final filled = _controller.text.length;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, _) => Transform.translate(
        offset: Offset(_offset.value, 0),
        child: Semantics(
          label: widget.semanticLabel ?? 'PIN',
          textField: true,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              TextField(
                controller: _controller,
                autofocus: widget.autoFocus,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                obscureText: true,
                obscuringCharacter: '●',
                onChanged: _changed,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                showCursor: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 1,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var i = 0; i < widget.length; i++)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < filled ? color.primary : color.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
