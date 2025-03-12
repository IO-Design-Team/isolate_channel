import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() async {
  final connection = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateMethodChannel('test', connection);

  tearDownAll(connection.close);

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

    test('unexpected result', () {
      expect(channel.invokeMethod<Object?>('return_null'), completes);
      expect(
        channel.invokeMethod<Object>('return_null'),
        throwsIsolateException(code: 'unexpected_result'),
      );
    });

    test('error result', () {
      expect(
        channel.invokeMethod('return_error'),
        throwsIsolateException(
          code: 'code',
          message: 'message',
          details: 'details',
        ),
      );
    });

    test('not implemented', () {
      expect(
        channel.invokeMethod('not_implemented'),
        throwsIsolateException(
          code: 'not_implemented',
          message: contains('not_implemented'),
        ),
      );
    });

    test('multiple connections', () {
      IsolateMethodChannel createChannel(int connections) {
        return IsolateMethodChannel(
          '',
          createConnection(connections: connections),
        );
      }

      expect(() => createChannel(1).invokeMethod('', ''), returnsNormally);

      expect(
        () => createChannel(2).invokeMethod('', ''),
        throwsIsolateException(code: 'multiple_connections'),
      );
    });
  });

  test('method throws exception', () {
    expect(
      channel.invokeMethod('throw_exception'),
      throwsIsolateException(
        code: 'unhandled_exception',
        message: contains('test#throw_exception'),
        details: contains('oops'),
      ),
    );
  });
}

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateMethodChannel('test', connection);
  channel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'invokeMethod':
      case 'invokeListMethod':
      case 'invokeMapMethod':
        return call.arguments;
      case 'return_null':
        return null;
      case 'return_error':
        return IsolateException(
          code: 'code',
          message: 'message',
          details: 'details',
        );
      case 'throw_exception':
        throw 'oops';
      default:
        return IsolateException.notImplemented(call.method);
    }
  });
}
