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

    test('owner issues', () {
      IsolateEventChannel createChannel(bool owner) {
        return IsolateEventChannel('', createConnection(owner: owner));
      }

      expect(
        () => createChannel(true).receiveBroadcastStream(),
        returnsNormally,
      );
      expect(
        () => createChannel(false).receiveBroadcastStream(),
        throwsA(isAIsolateException(code: 'not_owner')),
      );

      expect(
        () => createChannel(true).setStreamHandler(null),
        throwsA(isAIsolateException(code: 'owner')),
      );
      expect(
        () => createChannel(false).setStreamHandler(null),
        returnsNormally,
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
        events.success(null);
        events.error(code: 'code', message: 'message', details: 'details');
        events.endOfStream();
      },
      onCancel: (arguments) => print('onCancel: $arguments'),
    ),
  );
}
