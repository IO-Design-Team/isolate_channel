import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main(List<String> args, SendPort send) => eventsEntryPoint(send);

void eventsEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateEventChannel('test', connection);
  channel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (arguments, events) {
        events.success('Hello');
        events.success(null);
        events.error(
          code: 'code',
          message: 'message',
          details: 'details',
        );
        events.endOfStream();
      },
      onCancel: (arguments) => print('onCancel: $arguments'),
    ),
  );
}
