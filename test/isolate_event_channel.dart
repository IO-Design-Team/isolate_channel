import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() async {
  final (send, receive) = await spawnIsolate(isolateEntryPoint);
  final channel = IsolateEventChannel('test', send, receive);

  group('event channel', () {
    test('listen', () async {
      final stream = channel.receiveBroadcastStream().listen(print);
      // expect(await stream.first, 'Hello');
    });
  });
}

void isolateEntryPoint(SendPort send) {
  final receive= setupIsolate(send);

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
