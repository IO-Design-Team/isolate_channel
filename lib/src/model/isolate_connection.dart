import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/src/model/internal/method_invocation.dart';
import 'package:meta/meta.dart';

/// A connection between isolates
@immutable
class IsolateConnection {
  static const _channel = '_isolate_channel.IsolateConnection';

  final Set<SendPort> _sendPorts;

  /// Number of connections to this isolate
  int get connections => _sendPorts.length;

  /// Method invocations from other isolates by channel
  final _channels = <String, StreamController<MethodInvocation>>{};
  final void Function() _close;
  late final StreamSubscription _receiveSubscription;
  late final StreamSubscription _controlSubscription;

  /// Constructor
  IsolateConnection({
    SendPort? send,
    required Stream receive,
    required void Function() close,
  })  : _sendPorts = {if (send != null) send},
        _close = close {
    _receiveSubscription = receive.listen(
      (message) {
        final invocation = MethodInvocation.fromJson(message);
        _channels[invocation.channel]?.add(invocation);
      },
      onDone: _closeChannels,
    );

    // Handle new connections
    _controlSubscription = methodInvocations(_channel).listen((invocation) {
      switch (invocation.method) {
        case 'connect':
          _sendPorts.add(invocation.arguments);
        case 'disconnect':
          _sendPorts.remove(invocation.arguments);
        case 'addOnExitListener':
          Isolate.current.addOnExitListener(invocation.arguments);
        case 'addErrorListener':
          Isolate.current.addErrorListener(invocation.arguments);
      }
      invocation.result(null);
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
    return (_channels[channel] ??= StreamController.broadcast()).stream;
  }

  void _closeChannels() {
    for (final controller in _channels.values) {
      controller.close();
    }
  }

  Future<void> _invokeWithResponse(
    String channel,
    String method,
    dynamic arguments,
  ) {
    final receivePort = ReceivePort();
    invoke(channel, method, arguments, receivePort.sendPort);
    return receivePort.first;
  }

  /// Send a message to indicate this isolate has connected
  ///
  /// Returns a future that completes when the isolate we are connecting to
  /// responds to indicate a successful connection
  Future<void> isolateConnected(SendPort sendPort) {
    return _invokeWithResponse(_channel, 'connect', sendPort);
  }

  /// Send a message to indicate this isolate has disconnected
  ///
  /// Does not return a future because there could be many isolates connected
  void isolateDisconnected(SendPort sendPort) {
    invoke(_channel, 'disconnect', sendPort);
  }

  /// Add an on exit listener
  void addOnExitListener(SendPort sendPort) {
    invoke(_channel, 'addOnExitListener', sendPort);
  }

  /// Add an on error listener
  void addErrorListener(SendPort sendPort) {
    invoke(_channel, 'addErrorListener', sendPort);
  }

  /// Close the connection
  ///
  /// If this connection spawned the isolate, the isolate will be killed
  void close() {
    _controlSubscription.cancel();
    _receiveSubscription.cancel();
    _closeChannels();
    _close();
  }
}
