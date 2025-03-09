import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() async {
  final connection = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateEventChannel('test', connection);

  tearDownAll(connection.shutdown);

  group('event channel', () {
    test('listen', () {
      final stream = channel.receiveBroadcastStream();
      expect(
        stream,
        emitsInOrder([
          'Hello',
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
  });
}

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateEventChannel('test', connection);
  channel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (arguments, events) {
        events.success('Hello');
        events.error(code: 'code', message: 'message', details: 'details');
        events.endOfStream();
      },
      onCancel: (arguments) => print('onCancel: $arguments'),
    ),
  );
}
