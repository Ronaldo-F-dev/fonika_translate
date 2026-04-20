import 'dart:async';
import 'package:flutter/material.dart';
import '../fonika_client.dart';
import '../models/translation_result.dart';
import 'fonika_provider.dart';

/// A [TextField] that automatically translates its content in real-time.
///
/// As the user types, the field debounces the input (500ms) and displays
/// the live translation below or beside the input field.
///
/// Requires [FonikaProvider] in the widget tree.
///
/// Example:
/// ```dart
/// FonikaTranslationField(
///   controller: myController,
///   toLang: 'en',
///   fromLang: 'fr',
/// )
/// ```
class FonikaTranslationField extends StatefulWidget {
  /// Controller for the input text.
  final TextEditingController controller;

  /// Target language code (e.g. 'en', 'fr').
  final String toLang;

  /// Source language code (default 'auto' for auto-detection).
  final String fromLang;

  /// Whether to skip local translation lookup. Default false.
  final bool skipLocal;

  /// Whether to skip device cache. Default false.
  final bool skipDeviceCache;

  /// Custom builder to display the translation result.
  /// If null, a default gray text display is used.
  /// Called with the [TranslationResult] or an error message.
  final Widget Function(BuildContext context, AsyncSnapshot<TranslationResult> snapshot)?
      translationBuilder;

  /// Debounce duration for translation requests. Default 500ms.
  final Duration debounceDuration;

  /// All standard [TextField] parameters - decoration, style, maxLines, etc.
  final InputDecoration? decoration;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool readOnly;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;

  const FonikaTranslationField({
    Key? key,
    required this.controller,
    required this.toLang,
    this.fromLang = 'auto',
    this.skipLocal = false,
    this.skipDeviceCache = false,
    this.translationBuilder,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.decoration,
    this.style,
    this.maxLines,
    this.minLines,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<FonikaTranslationField> createState() => _FonikaTranslationFieldState();
}

class _FonikaTranslationFieldState extends State<FonikaTranslationField> {
  late FonikaTranslate _fonika;
  Timer? _debounceTimer;
  AsyncSnapshot<TranslationResult> _translationSnapshot =
      const AsyncSnapshot.withData(ConnectionState.none, null);
  String _lastTranslatedText = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fonika = FonikaProvider.of(context);
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();

    final text = widget.controller.text.trim();

    // Skip translation if empty
    if (text.isEmpty) {
      setState(() {
        _translationSnapshot =
            const AsyncSnapshot.withData(ConnectionState.none, null);
        _lastTranslatedText = '';
      });
      return;
    }

    // Skip if same as last translation
    if (text == _lastTranslatedText) {
      return;
    }

    setState(() {
      _translationSnapshot = const AsyncSnapshot.waiting();
    });

    _debounceTimer = Timer(widget.debounceDuration, () async {
      try {
        final result = await _fonika.translate(
          text,
          toLang: widget.toLang,
          fromLang: widget.fromLang,
          skipLocal: widget.skipLocal,
          skipDeviceCache: widget.skipDeviceCache,
        );

        if (mounted) {
          setState(() {
            _translationSnapshot =
                AsyncSnapshot.withData(ConnectionState.done, result);
            _lastTranslatedText = text;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _translationSnapshot = AsyncSnapshot.withError(
              ConnectionState.done,
              e,
              StackTrace.current,
            );
          });
        }
      }
    });

    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: widget.decoration,
          style: widget.style,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          readOnly: widget.readOnly,
          maxLength: widget.maxLength,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          onTap: widget.onTap,
          onSubmitted: widget.onSubmitted,
        ),
        const SizedBox(height: 8),
        _buildTranslationDisplay(),
      ],
    );
  }

  Widget _buildTranslationDisplay() {
    if (_translationSnapshot.data == null &&
        _translationSnapshot.connectionState != ConnectionState.waiting) {
      return const SizedBox.shrink();
    }

    if (widget.translationBuilder != null) {
      return widget.translationBuilder!(context, _translationSnapshot);
    }

    return _defaultTranslationBuilder();
  }

  Widget _defaultTranslationBuilder() {
    if (_translationSnapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_translationSnapshot.hasError) {
      final error = _translationSnapshot.error;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Error: ${error.toString()}',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    if (_translationSnapshot.hasData) {
      final result = _translationSnapshot.data!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          result.translatedText,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
