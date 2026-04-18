import 'package:flutter/material.dart';

import 'fonika_provider.dart';

/// A microphone icon button for live speech recognition.
///
/// Uses the device platform ASR (speech_to_text).
/// Tap once to start listening, tap again to stop.
///
/// [onResult] is called with the final recognized text.
/// [onPartialResult] is called on each intermediate result.
///
/// Requires [FonikaProvider] in the widget tree.
///
/// ```dart
/// FonikaListenButton(
///   language: 'fr',
///   onResult: (text) => print('Said: $text'),
///   onPartialResult: (text) => print('Partial: $text'),
/// )
/// ```
class FonikaListenButton extends StatefulWidget {
  final String language;
  final void Function(String text) onResult;
  final void Function(String text)? onPartialResult;
  final void Function(Object error)? onError;

  /// Icon shown when idle. Defaults to [Icons.mic].
  final Widget? idleIcon;

  /// Icon shown while listening. Defaults to a red [Icons.mic].
  final Widget? listeningIcon;

  final Color? idleColor;
  final Color? listeningColor;
  final double? iconSize;
  final ButtonStyle? style;

  /// Max duration to listen before stopping automatically.
  final Duration listenFor;

  /// Silence duration before stopping.
  final Duration pauseFor;

  const FonikaListenButton({
    super.key,
    required this.language,
    required this.onResult,
    this.onPartialResult,
    this.onError,
    this.idleIcon,
    this.listeningIcon,
    this.idleColor,
    this.listeningColor,
    this.iconSize,
    this.style,
    this.listenFor = const Duration(seconds: 30),
    this.pauseFor = const Duration(seconds: 3),
  });

  @override
  State<FonikaListenButton> createState() => _FonikaListenButtonState();
}

class _FonikaListenButtonState extends State<FonikaListenButton> {
  bool _listening = false;

  Future<void> _onTap() async {
    final client = FonikaProvider.of(context);

    if (_listening) {
      await client.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }

    setState(() => _listening = true);
    try {
      final started = await client.startListening(
        widget.language,
        onResult: (text, isFinal) {
          if (isFinal) {
            widget.onResult(text);
            if (mounted) setState(() => _listening = false);
          } else {
            widget.onPartialResult?.call(text);
          }
        },
        onDone: () {
          if (mounted) setState(() => _listening = false);
        },
        listenFor: widget.listenFor,
        pauseFor: widget.pauseFor,
      );
      if (!started && mounted) setState(() => _listening = false);
    } catch (e) {
      widget.onError?.call(e);
      if (mounted) setState(() => _listening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idleColor =
        widget.idleColor ?? Theme.of(context).colorScheme.primary;
    final listeningColor = widget.listeningColor ?? Colors.red;

    return IconButton(
      style: widget.style,
      onPressed: _onTap,
      icon: _listening
          ? widget.listeningIcon ??
              Icon(Icons.mic, color: listeningColor, size: widget.iconSize)
          : widget.idleIcon ??
              Icon(Icons.mic_none, color: idleColor, size: widget.iconSize),
    );
  }
}
