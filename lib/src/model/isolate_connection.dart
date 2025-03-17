import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// A connection between isolates
class IsolateConnection {
  static const _channel = '_isolate_channel.IsolateConnection';

  final Set<SendPort> _sendPorts;

  /// Number of connections to this isolate
  int get connections => _sendPorts.length;

  /// Stream of method invocations from other isolates
  final Stream<MethodInvocation> _receive;
  final void Function() _close;
  late final StreamSubscription _subscription;

  /// Constructor
  IsolateConnection({
    required SendPort send,
    required Stream receive,
    required void Function() close,
  })  : _sendPorts = {send},
        _receive = receive.map((message) => MethodInvocation.fromJson(message)),
        _close = close {
    // Handle new connections
    _subscription = methodInvocations(_channel).listen((invocation) {
      switch (invocation.method) {
        case 'connect':
          _sendPorts.add(invocation.arguments);
        case 'disconnect':
          _sendPorts.remove(invocation.arguments);
      }
    });
  }

  /// Send a method invocation to all connected isolates
  void invoke(
    String channel,
    String method,
    dynamic arguments, [
    SendPort? respond,
  ]) {
    for (final send in _sendPorts) {
      send.send(MethodInvocation(channel, method, arguments, respond).toJson());
    }
  }

  /// Stream of method invocations targeting [channel]
  Stream<MethodInvocation> methodInvocations(String channel) {
    return _receive.where((invocation) => invocation.channel == channel);
  }

  /// Send a message to indicate this isolate has connected
  void isolateConnected(SendPort sendPort) {
    invoke(_channel, 'connect', sendPort);
  }

  /// Send a message to indicate this isolate has disconnected
  void isolateDisconnected(SendPort sendPort) {
    invoke(_channel, 'disconnect', sendPort);
  }

  /// Close the connection
  void close() {
    _subscription.cancel();
    _close();
  }
}
