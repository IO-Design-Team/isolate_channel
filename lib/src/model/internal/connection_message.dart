import 'dart:isolate';

/// A message to register or unregister a [SendPort]
sealed class ConnectionMessage {
  /// The [SendPort] to register or unregister
  final SendPort sendPort;

  /// Constructor
  const ConnectionMessage(this.sendPort);
}

/// A message to register a [SendPort]
class IsolateConnect extends ConnectionMessage {
  /// Constructor
  const IsolateConnect(super.sendPort);
}

/// A message to unregister a [SendPort]
class IsolateDisconnect extends ConnectionMessage {
  /// Constructor
  const IsolateDisconnect(super.sendPort);
}
