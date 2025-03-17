import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

@pragma('vm:entry-point')
void main(List<String> args, SendPort send) => isolateEntryPoint(send);

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);

  final channel = IsolateMethodChannel('test', connection);
  channel.setMethodCallHandler((call) {
    switch (call.method) {
      case 'invokeMethod':
      case 'invokeListMethod':
      case 'invokeMapMethod':
        return call.arguments;
      case 'return_null':
        return null;
      case 'return_error':
        return IsolateException(
          code: 'code',
          message: 'message',
          details: 'details',
        );
      case 'throw_exception':
        throw 'oops';
      default:
        return call.notImplemented();
    }
  });
}
