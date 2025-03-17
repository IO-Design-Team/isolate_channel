import 'dart:isolate';

import 'package:isolate_channel/src/model/isolate_exception.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

/// A method invocation message
class MethodInvocation {
  static final _codec = StandardMessageCodec();

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
    _respond?.send(_codec.encodeMessage(result));
  }

  /// Respond with an unhandled exception
  void unhandled(Object error, StackTrace stackTrace) =>
      result(IsolateException.unhandled(channel, method, error, stackTrace));
}
