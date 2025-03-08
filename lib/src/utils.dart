import 'dart:isolate';

/// Helper function to spawn an isolate that supports channel communication
Future<(SendPort, Stream, void Function())> spawnIsolate<T>(
  void Function(SendPort message) entryPoint,
) async {
  final receivePort = ReceivePort();
  final receive = receivePort.asBroadcastStream();
  final isolate = await Isolate.spawn(entryPoint, receivePort.sendPort);
  final send = await receive.first as SendPort;
  void shutdown() {
    receivePort.close();
    isolate.kill();
  }

  return (send, receive, shutdown);
}

/// Helper function to set up an isolate for channel communication
Stream setupIsolate(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  final stream = receivePort.asBroadcastStream();
  stream
      .where((message) => message is SendPort)
      .cast<SendPort>()
      .listen((sendPort) => sendPort.send(receivePort.sendPort));
  return stream;
}
