/// An exception returned by an isolate
class IsolateException {
  /// The code of the exception
  final String code;

  /// The message of the exception
  final String? message;

  /// The details of the exception
  final Object? details;

  /// Constructor
  const IsolateException({required this.code, this.message, this.details});

  /// Copy with
  IsolateException copyWith({String? message, Object? details}) =>
      IsolateException(
        code: code,
        message: message ?? this.message,
        details: details ?? this.details,
      );

  @override
  String toString() =>
      'IsolateException(code: $code, message: $message, details: $details)';
}
