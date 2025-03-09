import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() async {
  final connection = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateMethodChannel('test', connection);

  tearDownAll(connection.shutdown);

  group('method channel', () {
    test('invoke method', () async {
      final result = await channel.invokeMethod('invokeMethod', 'Hello');
      expect(
        result,
        isAMethodInvocation(
          name: 'test',
          method: 'invokeMethod',
          arguments: 'Hello',
        ),
      );
    });

    test('invoke list method', () async {
      final result = await channel.invokeListMethod('invokeListMethod', [
        1,
        2,
        3,
      ]);
      expect(
        result,
        isAMethodInvocation(
          name: 'test',
          method: 'invokeListMethod',
          arguments: [1, 2, 3],
        ),
      );
    });

    test('invoke map method', () async {
      final result = await channel.invokeMapMethod('invokeMapMethod', {
        'a': 1,
        'b': 2,
        'c': 3,
      });
      expect(
        result,
        isAMethodInvocation(
          name: 'test',
          method: 'invokeMapMethod',
          arguments: {'a': 1, 'b': 2, 'c': 3},
        ),
      );
    });

    test('unexpected null result', () {
      expect(channel.invokeMethod<Object?>('return_null'), completes);
      expect(
        channel.invokeMethod<Object>('return_null'),
        throwsA(isAIsolateException(code: 'null_result')),
      );
    });

    test('error result', () {
      expect(
        channel.invokeMethod<int>('return_error'),
        throwsA(
          isAIsolateException(
            code: 'code',
            message: 'message',
            details: 'details',
          ),
        ),
      );
    });
  });
}

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateMethodChannel('test', connection);
  channel.setMethodCallHandler((call, result) {
    switch (call.method) {
      case 'return_null':
        result(null);
      case 'return_error':
        result(
          IsolateException(
            code: 'code',
            message: 'message',
            details: 'details',
          ),
        );
      default:
        result(call);
    }
  });
}
