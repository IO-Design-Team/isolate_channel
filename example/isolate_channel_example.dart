import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(isolateMain, receivePort.sendPort);
  final sendPort = await receivePort.first;

  final channel = IsolateMethodChannel('test', sendPort);
  channel.addMethodCallHandler(sendPort, (call, result) {
    print(call);
  });

  await channel.invokeMethod('test', 'Hello');
}

void isolateMain(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final channel = IsolateMethodChannel('test', receivePort.sendPort);

  void addHandlers(SendPort sendPort) {
    channel.addMethodCallHandler(sendPort, (call, result) {
      print(call);
      result('World!');
    });
  }

  addHandlers(receivePort.sendPort);

  receivePort
      .where((message) => message is SendPort)
      .cast<SendPort>()
      .listen(addHandlers);
}
