import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/isolate_message.dart';

/// A method channel for inter-isolate method invocation
class IsolateMethodChannel {
  /// The name of the channel
  final String name;
  final SendPort _sendPort;
  final Stream _receivePort;
  StreamSubscription? _handlerSubscription;

  /// Constructor
  IsolateMethodChannel(this.name, this._sendPort, this._receivePort);

  Future<T?> _invokeMethod<T>(String method, {dynamic arguments}) async {
    final receivePort = ReceivePort();
    _sendPort.send(
      IsolateMessage(name, method, arguments, receivePort.sendPort),
    );
    final result = await receivePort.first;
    receivePort.close();
    if (result is T?) {
      return result;
    } else {
      return Future.error(result);
    }
  }

  /// Invoke a method on the other isolate
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) {
    return _invokeMethod<T>(method, arguments: arguments);
  }

  /// Invoke a method on the other isolate and return a list
  Future<List<T>?> invokeListMethod<T>(
    String method, [
    dynamic arguments,
  ]) async {
    final result = await invokeMethod<List<dynamic>>(method, arguments);
    return result?.cast<T>();
  }

  /// Invoke a method on the other isolate and return a map
  Future<Map<K, V>?> invokeMapMethod<K, V>(
    String method, [
    dynamic arguments,
  ]) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result?.cast<K, V>();
  }

  /// Set a handler to receive method calls from the other isolate
  void setMethodCallHandler(
    void Function(IsolateMethodCall call, IsolateResult result)? handler,
  ) {
    _handlerSubscription?.cancel();
    if (handler == null) return;

    _handlerSubscription = _receivePort
        .where((message) => message is IsolateMessage && message.name == name)
        .cast<IsolateMessage>()
        .listen((message) {
          handler.call(
            IsolateMethodCall(message.method, message.arguments),
            IsolateResult(message.sendPort),
          );
        });
  }
}
