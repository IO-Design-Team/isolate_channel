import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main() async {
  final (send, receive) = await spawnIsolate(isolateEntryPoint);

  final channel = IsolateMethodChannel('example_channel', send, receive);
  final result = await channel.invokeMethod('example_method', 'Hello');
  print(result);
}

void isolateEntryPoint(SendPort send) {
  final receive = setupIsolate(send);

  final channel = IsolateMethodChannel('example_channel', send, receive);
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
