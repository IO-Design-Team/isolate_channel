import 'dart:isolate';

class IsolateMessage {
  /// The name of the channel sending the message
  final String name;

  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// The port to respond to
  final SendPort sendPort;

  /// Constructor
  const IsolateMessage(
    this.name,

    this.method,
    this.arguments,
    this.sendPort,
  );
}
