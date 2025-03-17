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
    _connection.invoke(name, method, arguments, receivePort.sendPort);
    final result = await receivePort.mapResults.first;

    receivePort.close();
    if (result is IsolateException) {
      return Future.error(result);
    } else if (result is T) {
      return result;
    } else {
      return Future.error(
        IsolateException(
          code: 'unexpected_result',
          message:
              'Expected result of type $T, but got $result which is of type ${result.runtimeType}',
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
        _connection.methodInvocations(name).listen((invocation) async {
      try {
        final result = await handler(
          IsolateMethodCall(name, invocation.method, invocation.arguments),
        );

        invocation.result(result);
      } catch (error, stackTrace) {
        invocation.unhandled(error, stackTrace);
      }
    });
  }
}
