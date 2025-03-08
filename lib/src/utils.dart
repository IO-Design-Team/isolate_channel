import 'dart:isolate';

/// Helper function to spawn an isolate that supports channel communication
Future<(SendPort, Stream)> spawnIsolate<T>(
  void Function(SendPort message) entryPoint,
) async {
  final receivePort = ReceivePort();
  final stream = receivePort.asBroadcastStream();
  await Isolate.spawn(entryPoint, receivePort.sendPort);
  final sendPort = await stream.first as SendPort;
  return (sendPort, stream);
}

/// Helper function to set up an isolate for channel communication
(SendPort, Stream) setupIsolate(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  final stream = receivePort.asBroadcastStream();
  stream
      .where((message) => message is SendPort)
      .cast<SendPort>()
      .listen((sendPort) => sendPort.send(receivePort.sendPort));
  return (receivePort.sendPort, stream);
}
