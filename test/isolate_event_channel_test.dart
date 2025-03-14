import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'entrypoint/event_channel.dart/events.dart';
import 'entrypoint/event_channel.dart/throws.dart';

void main() async {
  await testIsolateConnection(
      eventsEntryPoint, 'event_channel.dart/events.dart', (connection) {
    final channel = IsolateEventChannel('test', connection);

    test('event channel listen', () {
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
  });

  await testIsolateConnection(
      throwsEntryPoint, 'event_channel.dart/throws.dart', (connection) {
    final channel = IsolateEventChannel('test', connection);
    test('event channelonListen throws exception', () {
      expect(
        channel.receiveBroadcastStream().drain(),
        throwsIsolateException(
          code: 'unhandled_exception',
          message: contains('test#listen'),
          details: contains('oops'),
        ),
      );
    });
  });
}
