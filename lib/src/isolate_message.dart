import 'dart:isolate';

class IsolateMessage {
  /// The port to respond to
  final SendPort sendPort;

  /// The name of the channel sending the message
  final String name;

  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// Constructor
  const IsolateMessage(this.sendPort, this.name, this.method, this.arguments);
}
