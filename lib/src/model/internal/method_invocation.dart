import 'dart:isolate';

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
      'arguments': arguments,
      'sendPort': sendPort,
    };
  }
}
