import 'package:flutter/widgets.dart';

import '../models/translation_result.dart';
import 'fonika_provider.dart';

/// A [Text] widget that automatically translates its content.
///
/// Checks local translations first, then the device cache, then the API.
/// Shows [text] as a fallback while loading or on error.
///
/// Requires [FonikaProvider] in the widget tree.
///
/// ```dart
/// FonikaTranslatedText(
///   'Bonjour le monde',
///   toLang: 'en',
///   style: TextStyle(fontSize: 18),
/// )
///
/// // Key-based (resolved from local translations, no API call):
/// FonikaTranslatedText('app.title', toLang: 'fr')
/// ```
class FonikaTranslatedText extends StatefulWidget {
  final String text;
  final String toLang;
  final String fromLang;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Widget shown while translating. Defaults to [text] in grey.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Widget shown on error. Defaults to original [text].
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const FonikaTranslatedText(
    this.text, {
    super.key,
    required this.toLang,
    this.fromLang = 'auto',
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<FonikaTranslatedText> createState() => _FonikaTranslatedTextState();
}

class _FonikaTranslatedTextState extends State<FonikaTranslatedText> {
  late Future<TranslationResult> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _future = _translate();
    }
  }

  @override
  void didUpdateWidget(FonikaTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.toLang != widget.toLang) {
      _future = _translate();
    }
  }

  Future<TranslationResult> _translate() {
    return FonikaProvider.of(context).translate(
      widget.text,
      toLang: widget.toLang,
      fromLang: widget.fromLang,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TranslationResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              Text(widget.text,
                  style: widget.style?.copyWith(color: const Color(0xFFAAAAAA))
                    ?? const TextStyle(color: Color(0xFFAAAAAA)),
                  textAlign: widget.textAlign,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow);
        }
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Text(widget.text,
                  style: widget.style,
                  textAlign: widget.textAlign,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow);
        }
        return Text(
          snapshot.data!.translatedText,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}
