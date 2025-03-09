import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() async {
  final connection = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateMethodChannel('test', connection);

  tearDownAll(connection.shutdown);

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

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateMethodChannel('test', connection);
  channel.setMethodCallHandler((call, result) => result(call.arguments));
}
