import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// A handler for method invocations
typedef MethodCallHandler = FutureOr<dynamic> Function(IsolateMethodCall call);

/// A method channel for inter-isolate method invocation
class IsolateMethodChannel {
  /// The name of the channel
  final String name;
  final IsolateConnection _connection;
  StreamSubscription? _handlerSubscription;

  /// Constructor
  IsolateMethodChannel(this.name, this._connection);

  Future<T> _invokeMethod<T>(String method, {dynamic arguments}) async {
    if (_connection.connections > 1) {
      // Methods invocations cannot be sent to multiple isolates because only
      // one would be able to respond
      return Future.error(
        IsolateException(
          code: 'multiple_connections',
          message:
              'Methods cannot be invoked on a channel with multiple connections',
        ),
      );
    }
    final receivePort = ReceivePort();
    _connection.send(
      MethodInvocation(name, method, arguments, receivePort.sendPort),
    );
    final result = await receivePort.first;
    receivePort.close();
    final error = IsolateException.fromJson(result);
    if (error != null) {
      return Future.error(error);
    } else if (result is T) {
      return result;
    } else {
      return Future.error(
        IsolateException(
          code: 'unexpected_result',
          message: 'Expected $T, got $result which is a ${result.runtimeType}',
        ),
      );
    }
  }

  /// Invoke a method on the target isolate
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) {
    return _invokeMethod<T>(method, arguments: arguments);
  }

  /// Invoke a method on the target isolate and return a list
  Future<List<T>> invokeListMethod<T>(
    String method, [
    dynamic arguments,
  ]) async {
    final result = await invokeMethod<List<dynamic>>(method, arguments);
    return result.cast<T>();
  }

  /// Invoke a method on the target isolate and return a map
  Future<Map<K, V>> invokeMapMethod<K, V>(
    String method, [
    dynamic arguments,
  ]) async {
    final result = await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result.cast<K, V>();
  }

  /// Set a handler to receive method invocations from connected isolates
  void setMethodCallHandler(MethodCallHandler? handler) {
    _handlerSubscription?.cancel();
    if (handler == null) return;

    _handlerSubscription =
        _connection.methodInvocations(name).listen((message) async {
      try {
        var result = await handler(
          IsolateMethodCall(name, message.method, message.arguments),
        );
        if (result is IsolateException) {
          result = result.toJson();
        }
        message.sendPort?.send(result);
      } catch (error, stackTrace) {
        message.sendPort?.send(
          IsolateException.unhandled(name, message.method, error, stackTrace)
              .toJson(),
        );
      }
    });
  }
}
