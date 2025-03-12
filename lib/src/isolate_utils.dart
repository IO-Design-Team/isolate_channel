import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/connection_message.dart';

/// The entry point of an isolate
typedef IsolateEntryPoint = void Function(SendPort send);

/// Helper function to spawn an isolate that supports channel communication
///
/// [onConnect] can be used to register the [SendPort] with an
/// [IsolateNameServer]
Future<IsolateConnection> spawnIsolate<T>(
  IsolateEntryPoint entryPoint, {
  bool paused = false,
  bool errorsAreFatal = true,
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  String? debugName,
}) async {
  final receivePort = ReceivePort();
  final controlPort = ReceivePort();

  final isolate = await Isolate.spawn(
    entryPoint,
    receivePort.sendPort,
    paused: paused,
    errorsAreFatal: errorsAreFatal,
    onExit: controlPort.sendPort,
    onError: controlPort.sendPort,
    debugName: debugName,
  );
  final receive = receivePort.asBroadcastStream();
  final send = await receive.first as SendPort;
  onConnect?.call(send);
  void close() {
    receivePort.close();
    isolate.kill();
  }

  final connection =
      IsolateConnection(send: send, receive: receive, close: close);

  late final StreamSubscription controlSubscription;
  controlSubscription = controlPort.listen((message) {
    if (message == null) {
      // This is an exit message
      receivePort.close();
      controlPort.close();
      connection.close();
      controlSubscription.cancel();
      onExit?.call();
    } else {
      // This is an error message
      onError?.call(message[0], StackTrace.fromString(message[1]));
    }
  });

  return connection;
}

/// Helper function to set up an isolate for channel communication
IsolateConnection setupIsolate(SendPort send) {
  final receivePort = ReceivePort();
  send.send(receivePort.sendPort);
  final receive = receivePort.asBroadcastStream();
  final close = receivePort.close;

  return IsolateConnection(send: send, receive: receive, close: close);
}

/// Helper function to connect to an existing isolate
IsolateConnection connectToIsolate(SendPort send) {
  final receivePort = ReceivePort();
  send.send(IsolateConnect(receivePort.sendPort));
  final receive = receivePort.asBroadcastStream();
  void close() {
    send.send(IsolateDisconnect(receivePort.sendPort));
    receivePort.close();
  }

  return IsolateConnection(send: send, receive: receive, close: close);
}
