import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/src/isolate_method_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';
import 'package:meta/meta.dart';

/// A connection between isolates
@immutable
class IsolateConnection {
  final Set<SendPort> _sendPorts;

  /// Number of connections to this isolate
  int get connections => _sendPorts.length;

  /// Stream of method invocations from other isolates
  final Stream<MethodInvocation> _receive;
  final void Function() _close;
  late final _connectionChannel =
      IsolateMethodChannel('_isolate_channel.IsolateConnection', this);

  /// Constructor
  IsolateConnection({
    required SendPort send,
    required Stream receive,
    required void Function() close,
  })  : _sendPorts = {send},
        _receive = receive.map((message) => MethodInvocation.fromJson(message)),
        _close = close {
    // Handle new connections
    _connectionChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'connect':
          _sendPorts.add(call.arguments);
        case 'disconnect':
          _sendPorts.remove(call.arguments);
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
  Future<void> isolateConnected(SendPort sendPort) {
    return _connectionChannel.invokeMethod('connect', sendPort);
  }

  /// Send a message to indicate this isolate has disconnected
  Future<void> isolateDisconnected(SendPort sendPort) {
    return _connectionChannel.invokeMethod('disconnect', sendPort);
  }

  /// Close the connection
  ///
  /// If this connection spawned the isolate, the isolate will be killed
  void close() {
    _connectionChannel.setMethodCallHandler(null);
    _close();
  }
}
