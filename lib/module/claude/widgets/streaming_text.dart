import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Efek mengetik: teks terungkap bertahap + kursor berkedip.
/// Dipakai untuk pesan AI yang sedang streaming (zensasi sama dengan
/// animasi sistem: 220ms easeOutCubic untuk transisi selesai).
class StreamingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool streaming;

  const StreamingText({
    super.key,
    required this.text,
    this.style,
    this.streaming = true,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  int _shown = 0;
  Timer? _timer;
  bool _cursorOn = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _shown = widget.streaming ? 0 : widget.text.length;
    if (widget.streaming) _startReveal();
    _cursorTimer =
        Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (!mounted) return;
      setState(() => _cursorOn = !_cursorOn);
    });
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.streaming) {
      _timer?.cancel();
      if (_shown != widget.text.length) {
        setState(() => _shown = widget.text.length);
      }
    } else if (widget.text.length > _shown && _timer == null) {
      _startReveal();
    }
  }

  void _startReveal() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 18), (_) {
      if (!mounted) return;
      if (_shown >= widget.text.length) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      setState(() => _shown = (_shown + 2).clamp(0, widget.text.length));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final TextStyle style = widget.style ??
        TextStyle(
          fontSize: AppDims.chatFontSize,
          height: AppDims.chatLineHeight,
          color: c.textPrimary,
        );
    final String visible =
        widget.text.substring(0, _shown.clamp(0, widget.text.length));
    return Text.rich(
      TextSpan(
        text: visible,
        style: style,
        children: [
          if (widget.streaming)
            TextSpan(
              text: '▍',
              style: style.copyWith(
                color: _cursorOn ? c.accent : Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}
