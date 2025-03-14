/// An exception returned by an isolate
class IsolateException {
  static const _identifier = 'isolate_channel.IsolateException';

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

  /// From json
  ///
  /// Returns null if the json is invalid
  static IsolateException? fromJson(Object? json) {
    if (json == null || json is! Map || json['identifier'] != _identifier) {
      return null;
    }
    return IsolateException(
      code: json['code'],
      message: json['message'],
      details: json['details'],
    );
  }

  /// To json
  Map<String, dynamic> toJson() => {
        'identifier': _identifier,
        'code': code,
        if (message != null) 'message': message,
        if (details != null) 'details': details,
      };
}
