import 'dart:isolate';

import 'package:isolate_channel/src/model/isolate_exception.dart';

/// A method invocation message
class MethodInvocation {
  /// The name of the channel sending the message
  final String channel;

  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// The port to respond to
  ///
  /// If null, the method is not expected to respond
  final SendPort? sendPort;

  /// Constructor
  const MethodInvocation(
    this.channel,
    this.method,
    this.arguments,
    this.sendPort,
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
      if (sendPort != null) 'sendPort': sendPort,
    };
  }

  /// Respond with a result
  void result(Object result) => sendPort?.send(result);

  /// Respond with an unhandled exception
  void unhandled(Object error, StackTrace stackTrace) => sendPort?.send(
        IsolateException.unhandled(channel, method, error, stackTrace).toJson(),
      );
}
