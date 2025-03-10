import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/src/model/internal/connection_message.dart';

/// A connection between isolates
class IsolateConnection {
  /// If this connection was initiated by this isolate
  final bool owner;
  final Set<SendPort> _sendPorts;

  /// Number of connections to this isolate
  int get connections => _sendPorts.length;

  /// Stream of messages from other isolates
  final Stream receive;
  final void Function() _shutdown;
  late final StreamSubscription _subscription;

  /// Constructor
  IsolateConnection({
    required this.owner,
    required SendPort send,
    required this.receive,
    required void Function() shutdown,
  })  : _sendPorts = {send},
        _shutdown = shutdown {
    // Handle new connections
    _subscription = receive
        .where((message) => message is ConnectionMessage)
        .cast<ConnectionMessage>()
        .listen((message) {
      switch (message) {
        case IsolateConnect():
          _sendPorts.add(message.sendPort);
        case IsolateDisconnect():
          _sendPorts.remove(message.sendPort);
      }
    });
  }

  /// Send a message to all connected isolates
  void send(Object? message) {
    for (final sendPort in _sendPorts) {
      sendPort.send(message);
    }
  }

  /// Shutdown the connection
  void shutdown() {
    _subscription.cancel();
    _shutdown();
  }
}
