import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main() async {
  final (sendPort, stream) = await spawnIsolate(isolateMain);

  final channel = IsolateMethodChannel('test', sendPort, stream);
  channel.setMethodCallHandler((call, result) {
    print(call);
  });

  final result = await channel.invokeMethod('test', 'Hello');
  print(result);
}

void isolateMain(SendPort initSendPort) {
  final (sendPort, stream) = setupIsolate(initSendPort);

  final channel = IsolateMethodChannel('test', sendPort, stream);
  channel.setMethodCallHandler((call, result) {
    print(call.arguments);
    result('World!');
  });
}
