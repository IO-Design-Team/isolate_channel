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

  /// Constructor for a not implemented exception
  const IsolateException.notImplemented(String method)
      : code = 'not_implemented',
        message = 'Method $method not implemented',
        details = null;

  /// Constructor for an unhandled exception
  IsolateException.unhandled(
    String channel,
    String method,
    Object error,
    StackTrace stackTrace,
  )   : code = 'unhandled_exception',
        message = 'Unhandled exception in $channel#$method',
        details = [error.toString(), stackTrace.toString()];

  @override
  String toString() =>
      'IsolateException(code: $code, message: $message, details: $details)';
}
