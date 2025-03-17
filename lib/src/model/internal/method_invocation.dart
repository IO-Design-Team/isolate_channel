import 'dart:isolate';

import 'package:isolate_channel/src/model/isolate_exception.dart';

/// A method invocation message
class MethodInvocation {
  /// Null result placeholder since null cannot be sent to URI isolates
  static const nullResult = '_isolate_channel.null';

  /// The name of the channel sending the message
  final String channel;

  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// The port to respond to
  ///
  /// If null, the method is not expected to respond
  final SendPort? _respond;

  /// Constructor
  const MethodInvocation(
    this.channel,
    this.method,
    this.arguments,
    this._respond,
  );

  /// From json
  factory MethodInvocation.fromJson(Map<String, dynamic> json) {
    return MethodInvocation(
      json['channel'],
      json['method'],
      json['arguments'],
      json['sendPort'],
    );
  }

  /// To json
  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'method': method,
      if (arguments != null) 'arguments': arguments,
      if (_respond != null) 'sendPort': _respond,
    };
  }

  /// Respond with a result
  void result(Object? result) {
    if (result is IsolateException) {
      result = result.toJson();
    }
    _respond?.send(result ?? nullResult);
  }

  /// Respond with an unhandled exception
  void unhandled(Object error, StackTrace stackTrace) =>
      result(IsolateException.unhandled(channel, method, error, stackTrace));
}

/// Extension on [Stream]
extension StreamExtension on Stream {
  /// Handle deserialization of invocation results
  Stream<Object?> get mapResults => map((result) {
        if (result == MethodInvocation.nullResult) {
          return null;
        }

        final error = IsolateException.fromJson(result);
        if (error != null) {
          return error;
        }
        return result;
      });
}
