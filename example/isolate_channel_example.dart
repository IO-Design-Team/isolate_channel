import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

void main() async {
  final connection = await spawnIsolate(isolateEntryPoint);

  final methodChannel = IsolateMethodChannel('method_channel', connection);
  final eventChannel = IsolateEventChannel('event_channel', connection);

  final result = await methodChannel.invokeMethod('example_method', 'Hello');
  print(result);

  final stream = eventChannel.receiveBroadcastStream();
  stream.listen(print);

  await stream.drain();
  connection.shutdown();
}

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final methodChannel = IsolateMethodChannel('method_channel', connection);
  methodChannel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'example_method':
        print(call.arguments);
        return 'World!';
      default:
        return IsolateException.notImplemented(call.method);
    }
  });

  final eventChannel = IsolateEventChannel('event_channel', connection);
  eventChannel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (arguments, sink) {
        sink.success(arguments);
        sink.error(
          code: 'error',
          message: 'Something went wrong',
          details: 1234,
        );
        sink.endOfStream();
      },
      onCancel: (arguments) => print('Canceled $arguments'),
    ),
  );
}
