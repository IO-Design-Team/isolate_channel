import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() async {
  final (send, receive, shutdown) = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateEventChannel('test', send, receive);

  tearDownAll(shutdown);

  group('event channel', () {
    test('listen', () {
      final stream = channel.receiveBroadcastStream();
      expect(stream, emitsInOrder(['Hello', emitsDone]));
    });
  });
}

void isolateEntryPoint(SendPort send) {
  final receive = setupIsolate(send);

  final channel = IsolateEventChannel('test', send, receive);
  channel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (arguments, events) {
        events.success('Hello');
        events.endOfStream();
      },
      onCancel: (arguments) => print('onCancel: $arguments'),
    ),
  );
}
