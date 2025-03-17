import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

/// The entry point of an isolate spawned with [Isolate.spawn]
typedef IsolateEntryPoint = void Function(SendPort send);

/// The entry point of an isolate spawned with [Isolate.spawnUri]
typedef UriIsolateEntryPoint = void Function(List<String> args, SendPort send);

Future<IsolateConnection> _spawnIsolate({
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  required Future<Isolate> Function(ReceivePort receive, ReceivePort control)
      spawn,
}) async {
  final receivePort = ReceivePort();
  final controlPort = ReceivePort();

  final isolate = await spawn(receivePort, controlPort);

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
}) {
  return _spawnIsolate(
    onConnect: onConnect,
    onExit: onExit,
    onError: onError,
    spawn: (receivePort, controlPort) => Isolate.spawn(
      entryPoint,
      receivePort.sendPort,
      paused: paused,
      errorsAreFatal: errorsAreFatal,
      onExit: controlPort.sendPort,
      onError: controlPort.sendPort,
      debugName: debugName,
    ),
  );
}

/// Helper function to spawn an isolate by URI
Future<IsolateConnection> spawnUriIsolate<T>(
  Uri uri, {
  bool paused = false,
  bool errorsAreFatal = true,
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  String? debugName,
}) {
  return _spawnIsolate(
    onConnect: onConnect,
    onExit: onExit,
    onError: onError,
    spawn: (receivePort, controlPort) => Isolate.spawnUri(
      uri,
      [],
      receivePort.sendPort,
      paused: paused,
      errorsAreFatal: errorsAreFatal,
      onExit: controlPort.sendPort,
      onError: controlPort.sendPort,
      debugName: debugName,
    ),
  );
}

/// Helper function to set up an isolate for channel communication
IsolateConnection setupIsolate(SendPort send) {
  final receivePort = ReceivePort();
  send.send(receivePort.sendPort);

  return IsolateConnection(
    send: send,
    receive: receivePort.asBroadcastStream(),
    close: receivePort.close,
  );
}

/// Helper function to connect to an existing isolate
IsolateConnection connectToIsolate(SendPort send) {
  final receivePort = ReceivePort();
  final receive = receivePort.asBroadcastStream();
  late final IsolateConnection connection;
  void close() {
    connection.isolateDisconnected(receivePort.sendPort);
    receivePort.close();
  }

  connection = IsolateConnection(send: send, receive: receive, close: close);
  connection.isolateConnected(receivePort.sendPort);

  return connection;
}
