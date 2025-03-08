import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() async {
  final (send, receive) = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateMethodChannel('test', send, receive);

  group('method channel', () {
    test('invoke method', () async {
      final result = await channel.invokeMethod('invokeMethod', 'Hello');
      expect(result, 'Hello');
    });

    test('invoke list method', () async {
      final result = await channel.invokeListMethod('invokeListMethod', [
        1,
        2,
        3,
      ]);
      expect(result, [1, 2, 3]);
    });

    test('invoke map method', () async {
      final result = await channel.invokeMapMethod('invokeMapMethod', {
        'a': 1,
        'b': 2,
        'c': 3,
      });
      expect(result, {'a': 1, 'b': 2, 'c': 3});
    });
  });
}

void isolateEntryPoint(SendPort sendPort) {
  final (send, receive) = setupIsolate(sendPort);

  final channel = IsolateMethodChannel('test', send, receive);
  channel.setMethodCallHandler((call, result) => result(call.arguments));
}
