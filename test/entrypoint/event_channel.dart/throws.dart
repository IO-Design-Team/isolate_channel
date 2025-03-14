import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main(List<String> args, SendPort send) => throwsEntryPoint(send);

void throwsEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateEventChannel('test', connection);
  channel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (_, __) => throw 'oops',
    ),
  );
}
