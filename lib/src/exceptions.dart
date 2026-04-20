/// Base exception class for all fonika_translate errors.
abstract class FonikaException implements Exception {
  final String message;

  FonikaException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a language code is not supported by the API.
class LanguageNotSupportedException extends FonikaException {
  final String languageCode;

  LanguageNotSupportedException(this.languageCode)
      : super('Language "$languageCode" is not supported');
}

/// Thrown when a network error occurs (timeout, connection failed, etc).
class FonikaNetworkException extends FonikaException {
  final int? statusCode;
  final dynamic originalError;

  FonikaNetworkException(String message,
      {this.statusCode, this.originalError})
      : super(message);
}

/// Thrown when API authentication fails (missing or invalid token).
class FonikaAuthException extends FonikaException {
  FonikaAuthException(String message) : super(message);
}

/// Thrown when FonikaTranslate has not been initialized.
class FonikaInitException extends FonikaException {
  FonikaInitException()
      : super(
            'FonikaTranslate not initialized. Call await fonika.init() first.');
}

/// Thrown when a speech-to-text (ASR) operation fails.
class FonikaAsrException extends FonikaException {
  FonikaAsrException(String message) : super(message);
}

/// Thrown when a text-to-speech (TTS) operation fails.
class FonikaTtsException extends FonikaException {
  FonikaTtsException(String message) : super(message);
}

/// Thrown when a PDF operation fails (parsing, extraction, translation).
class FonikaPdfException extends FonikaException {
  FonikaPdfException(String message) : super(message);
}

/// Thrown when an API error occurs (5xx, 4xx, or other HTTP errors).
class FonikaApiException extends FonikaException {
  final int statusCode;
  final String? responseBody;

  FonikaApiException(this.statusCode, String message,
      {this.responseBody})
      : super(message);
}
