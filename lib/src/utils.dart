import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/connection_message.dart';

/// Helper function to spawn an isolate that supports channel communication
Future<IsolateConnection> spawnIsolate<T>(
  void Function(SendPort message) entryPoint,
) async {
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);
  final receive = receivePort.asBroadcastStream();
  final send = await receive.first as SendPort;
  void shutdown() {
    receivePort.close();
    isolate.kill();
  }

  return IsolateConnection(
    owner: true,
    send: send,
    receive: receive,
    shutdown: shutdown,
  );
}

/// Helper function to set up an isolate for channel communication
IsolateConnection setupIsolate(SendPort send) {
  final receivePort = ReceivePort();
  send.send(receivePort.sendPort);
  final receive = receivePort.asBroadcastStream();
  final shutdown = receivePort.close;

  return IsolateConnection(
    owner: false,
    send: send,
    receive: receive,
    shutdown: shutdown,
  );
}

/// Helper function to connect to an existing isolate
Future<IsolateConnection> connectToIsolate(SendPort send) async {
  final receivePort = ReceivePort();
  send.send(IsolateConnect(receivePort.sendPort));
  final receive = receivePort.asBroadcastStream();
  void shutdown() {
    send.send(IsolateDisconnect(receivePort.sendPort));
    receivePort.close();
  }

  return IsolateConnection(
    owner: true,
    send: send,
    receive: receive,
    shutdown: shutdown,
  );
}
