import 'dart:isolate';

/// A method invocation message
class MethodInvocation {
  /// The name of the channel sending the message
  final String name;

  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// The port to respond to
  ///
  /// If null, the method is not expected to respond
  final SendPort? sendPort;

  /// Constructor
  const MethodInvocation(this.name, this.method, this.arguments, this.sendPort);
}
