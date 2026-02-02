import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

/// The entry point of an isolate spawned with [Isolate.spawn]
typedef IsolateEntryPoint = void Function(SendPort? send);

/// The entry point of an isolate spawned with [Isolate.spawnUri]
typedef UriIsolateEntryPoint = void Function(List<String> args, SendPort send);

/// A function that spawns an isolate
///
/// The return type is `dynamic` to support custom isolate implementations such
/// as `FlutterIsolate`. The returned object MUST implement a `kill()` method.
typedef IsolateSpawner = Future<dynamic> Function(
  /// The child isolate sends messages to the parent isolate on this port
  SendPort send,

  /// The child isolate sends control messages to the parent isolate on this port
  SendPort control,
);

/// Raw isolate connection spawner
///
/// Useful for custom isolate implementations such as `FlutterIsolate`.
///
/// [onConnect] can be used to register the [SendPort] with an
/// [IsolateNameServer]. Prefer using `onSendPortReady` in `setupIsolate`
/// instead to support headless restarts such as in an Android foreground
/// service.
Future<IsolateConnection> spawnIsolateConnection({
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  required IsolateSpawner spawn,
}) async {
  final receivePort = ReceivePort();
  final controlPort = ReceivePort();

  final isolate = await spawn(receivePort.sendPort, controlPort.sendPort);

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

  connection.addOnExitListener(controlPort.sendPort);
  connection.addErrorListener(controlPort.sendPort);

  return connection;
}

/// Helper function to spawn an isolate that supports channel communication
Future<IsolateConnection> spawnIsolate(
  IsolateEntryPoint entryPoint, {
  bool paused = false,
  bool errorsAreFatal = true,
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  String? debugName,
}) {
  return spawnIsolateConnection(
    onConnect: onConnect,
    onExit: onExit,
    onError: onError,
    spawn: (send, control) => Isolate.spawn(
      entryPoint,
      send,
      paused: paused,
      errorsAreFatal: errorsAreFatal,
      onExit: control,
      onError: control,
      debugName: debugName,
    ),
  );
}

/// Helper function to spawn an isolate by URI
Future<IsolateConnection> spawnUriIsolate(
  Uri uri, {
  bool paused = false,
  bool errorsAreFatal = true,
  void Function(SendPort send)? onConnect,
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
  String? debugName,
}) {
  return spawnIsolateConnection(
    onConnect: onConnect,
    onExit: onExit,
    onError: onError,
    spawn: (send, control) => Isolate.spawnUri(
      uri,
      [],
      send,
      paused: paused,
      errorsAreFatal: errorsAreFatal,
      onExit: control,
      onError: control,
      debugName: debugName,
    ),
  );
}

/// Helper function to set up an isolate for channel communication
///
/// [send] is the [SendPort] used to send messages to the parent isolate. This
/// is nullable to support cases where the child isolate is restarted.
///
/// [onSendPortReady] can be used to register the [SendPort] with an
/// [IsolateNameServer]. This [SendPort] is the port used to send messages to
/// this isolate.
IsolateConnection setupIsolate(
  SendPort? send, {
  void Function(SendPort send)? onSendPortReady,
}) {
  final receivePort = ReceivePort();
  final sendPort = receivePort.sendPort;
  send?.send(sendPort);
  onSendPortReady?.call(sendPort);

  return IsolateConnection(
    send: send,
    receive: receivePort.asBroadcastStream(),
    close: receivePort.close,
  );
}

/// Helper function to connect to an existing isolate
Future<IsolateConnection> connectToIsolate(
  SendPort send, {
  void Function()? onExit,
  void Function(String error, StackTrace stackTrace)? onError,
}) async {
  final receivePort = ReceivePort();
  final controlPort = ReceivePort();

  final receive = receivePort.asBroadcastStream();
  late final IsolateConnection connection;
  void close() {
    connection.isolateDisconnected(receivePort.sendPort);
    receivePort.close();
  }

  connection = IsolateConnection(send: send, receive: receive, close: close);

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

  await connection.isolateConnected(receivePort.sendPort);
  connection.addOnExitListener(controlPort.sendPort);
  connection.addErrorListener(controlPort.sendPort);

  return connection;
}
