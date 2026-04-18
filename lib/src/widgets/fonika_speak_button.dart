import 'package:flutter/material.dart';

import 'fonika_provider.dart';

/// An icon button that plays TTS for [text] in [language].
///
/// - African languages (fon/yoruba/hausa): fetches audio from the 229Langues API.
/// - All other languages: uses the device platform TTS (flutter_tts).
///
/// Tapping again while speaking stops the audio.
///
/// Requires [FonikaProvider] in the widget tree.
///
/// ```dart
/// FonikaSpeakButton(text: 'Bonjour', language: 'fr')
/// FonikaSpeakButton(text: 'È dó wɛ̀', language: 'fon')
/// ```
class FonikaSpeakButton extends StatefulWidget {
  final String text;
  final String language;

  /// Icon shown when idle. Defaults to [Icons.volume_up].
  final Widget? idleIcon;

  /// Icon shown while speaking. Defaults to [Icons.stop].
  final Widget? speakingIcon;

  /// Icon shown while loading audio (African TTS API call).
  final Widget? loadingIcon;

  final Color? color;
  final double? iconSize;
  final ButtonStyle? style;

  const FonikaSpeakButton({
    super.key,
    required this.text,
    required this.language,
    this.idleIcon,
    this.speakingIcon,
    this.loadingIcon,
    this.color,
    this.iconSize,
    this.style,
  });

  @override
  State<FonikaSpeakButton> createState() => _FonikaSpeakButtonState();
}

class _FonikaSpeakButtonState extends State<FonikaSpeakButton> {
  _SpeakState _state = _SpeakState.idle;

  Future<void> _onTap() async {
    final client = FonikaProvider.of(context);

    if (_state == _SpeakState.speaking) {
      await client.stopSpeaking();
      if (mounted) setState(() => _state = _SpeakState.idle);
      return;
    }

    setState(() => _state = _SpeakState.loading);
    try {
      await client.speak(widget.text, widget.language);
    } finally {
      if (mounted) setState(() => _state = _SpeakState.idle);
    }
    if (mounted) setState(() => _state = _SpeakState.speaking);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    Widget icon;
    switch (_state) {
      case _SpeakState.loading:
        icon = widget.loadingIcon ??
            SizedBox(
              width: widget.iconSize ?? 24,
              height: widget.iconSize ?? 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            );
      case _SpeakState.speaking:
        icon = widget.speakingIcon ??
            Icon(Icons.stop, color: color, size: widget.iconSize);
      case _SpeakState.idle:
        icon = widget.idleIcon ??
            Icon(Icons.volume_up, color: color, size: widget.iconSize);
    }

    return IconButton(
      style: widget.style,
      onPressed: _state == _SpeakState.loading ? null : _onTap,
      icon: icon,
    );
  }
}

enum _SpeakState { idle, loading, speaking }
