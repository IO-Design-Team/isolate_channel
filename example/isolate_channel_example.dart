import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main() async {
  final connection = await spawnIsolate(isolateEntryPoint);

  final channel = IsolateMethodChannel('example_channel', connection);
  final result = await channel.invokeMethod('example_method', 'Hello');
  print(result);

  connection.shutdown();
}

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateMethodChannel('example_channel', connection);
  channel.setMethodCallHandler((call, result) {
    switch (call.method) {
      case 'example_method':
        print(call.arguments);
        result('World!');
      default:
        throw UnimplementedError('Unknown method: ${call.method}');
    }
  });
}
