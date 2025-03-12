import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('event channel', () {
    test('listen', () async {
      void isolateEntryPoint(SendPort send) {
        final connection = setupIsolate(send);

        final channel = IsolateEventChannel('test', connection);
        channel.setStreamHandler(
          IsolateStreamHandler.inline(
            onListen: (arguments, events) {
              events.success('Hello');
              events.success(null);
              events.error(
                  code: 'code', message: 'message', details: 'details');
              events.endOfStream();
            },
            onCancel: (arguments) => print('onCancel: $arguments'),
          ),
        );
      }

      final connection = await spawnIsolate(isolateEntryPoint);
      addTearDown(connection.close);
      final channel = IsolateEventChannel('test', connection);

      final stream = channel.receiveBroadcastStream();
      expect(
        stream,
        emitsInOrder([
          'Hello',
          null,
          emitsError(
            isAIsolateException(
              code: 'code',
              message: 'message',
              details: 'details',
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('onListen throws exception', () async {
      void isolateEntryPoint(SendPort send) {
        final connection = setupIsolate(send);

        final channel = IsolateEventChannel('test', connection);
        channel.setStreamHandler(
          IsolateStreamHandler.inline(
            onListen: (_, __) => throw 'oops',
          ),
        );
      }

      final connection = await spawnIsolate(isolateEntryPoint);
      addTearDown(connection.close);
      final channel = IsolateEventChannel('test', connection);

      expect(
        channel.receiveBroadcastStream().drain(),
        throwsA(
          isAIsolateException(
            code: 'unhandled_exception',
            message: contains('test#listen'),
            details: contains('oops'),
          ),
        ),
      );
    });
  });
}
