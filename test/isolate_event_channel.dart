import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

import 'isolate_method_channel.dart';

void main() async {
  final (send, receive) = await spawnIsolate(isolateEntryPoint);

  final channel = IsolateEventChannel('test', send, receive);
}

void isolateEntryPoint(SendPort sendPort) {
  final (send, receive) = setupIsolate(sendPort);

  final channel = IsolateEventChannel('test', send, receive);
  channel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (arguments, events) {
        events.success('Hello');
      },
      onCancel: (arguments) {
        print('Cancel');
      },
    ),
  );
}
