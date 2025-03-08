import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/isolate_message.dart';

class IsolateMethodChannel {
  final String name;
  final SendPort _sendPort;
  final _handlerSubscriptions = <StreamSubscription>[];

  IsolateMethodChannel(this.name, this._sendPort);

  Future<T?> _invokeMethod<T>(String method, {dynamic arguments}) async {
    final receivePort = ReceivePort();
    _sendPort.send(
      IsolateMessage(receivePort.sendPort, name, method, arguments),
    );
    final result = await receivePort.first;
    receivePort.close();
    if (result is T?) {
      return result;
    } else {
      return Future.error(result);
    }
  }

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) {
    return _invokeMethod<T>(method, arguments: arguments);
  }

  Future<List<T>?> invokeListMethod<T>(
    String method, [
    dynamic arguments,
  ]) async {
    final result = await invokeMethod<List<dynamic>>(method, arguments);
    return result?.cast<T>();
  }

  Future<Map<K, V>?> invokeMapMethod<K, V>(
    String method, [
    dynamic arguments,
  ]) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result?.cast<K, V>();
  }

  void addMethodCallHandler(
    SendPort sendPort,
    void Function(IsolateMethodCall call, IsolateResult result)
    handler,
  ) {
    final receivePort = ReceivePort();
    final subscription = receivePort
        .where((message) => message is IsolateMessage && message.name == name)
        .cast<IsolateMessage>()
        .listen((message) {
          if (message.method == 'addMethodCallHandler') {
            message.sendPort.send(sendPort);
          } else {
            handler.call(
              IsolateMethodCall(message.method, message.arguments),
              IsolateResult(message.sendPort),
            );
          }
        });
    _handlerSubscriptions.add(subscription);
    sendPort.send(
      IsolateMessage(
        receivePort.sendPort,
        name,
        'addMethodCallHandler',
        handler,
      ),
    );
  }

  void close() {
    for (final subscription in _handlerSubscriptions) {
      subscription.cancel();
    }
    _handlerSubscriptions.clear();
  }
}
