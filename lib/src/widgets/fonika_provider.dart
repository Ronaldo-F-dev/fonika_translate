import 'package:flutter/widgets.dart';

import '../fonika_client.dart';

/// Provides a [FonikaTranslate] instance to the widget tree.
///
/// Wrap your app (or a subtree) with [FonikaProvider] so that
/// [FonikaTranslatedText], [FonikaSpeakButton], and [FonikaListenButton]
/// can access the client without explicit passing.
///
/// ```dart
/// FonikaProvider(
///   client: fonika,
///   child: MaterialApp(...),
/// )
/// ```
class FonikaProvider extends InheritedWidget {
  final FonikaTranslate client;

  const FonikaProvider({
    super.key,
    required this.client,
    required super.child,
  });

  /// Returns the nearest [FonikaTranslate] in the tree.
  ///
  /// Throws if no [FonikaProvider] is found.
  static FonikaTranslate of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FonikaProvider>();
    assert(
      provider != null,
      'FonikaProvider.of() called with no FonikaProvider in the widget tree.\n'
      'Make sure to wrap your app with FonikaProvider(client: ..., child: ...).',
    );
    return provider!.client;
  }

  /// Returns the nearest [FonikaTranslate] or null if not found.
  static FonikaTranslate? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FonikaProvider>()
        ?.client;
  }

  @override
  bool updateShouldNotify(FonikaProvider oldWidget) =>
      client != oldWidget.client;
}
