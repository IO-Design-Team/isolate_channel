import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main() async {
  final receivePort = ReceivePort();
  final stream = receivePort.asBroadcastStream();
  await Isolate.spawn(isolateMain, receivePort.sendPort);
  final sendPort = await stream.first;

  final channel = IsolateMethodChannel('test', sendPort, stream);
  channel.setMethodCallHandler((call, result) {
    print(call);
  });

  final result = await channel.invokeMethod('test', 'Hello');
  print(result);
}

void isolateMain(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final stream = receivePort.asBroadcastStream();

  final channel = IsolateMethodChannel('test', receivePort.sendPort, stream);
  channel.setMethodCallHandler((call, result) {
    print(call.arguments);
    result('World!');
  });

  stream
      .where((message) => message is SendPort)
      .cast<SendPort>()
      .listen((sendPort) => sendPort.send(receivePort.sendPort));
}
