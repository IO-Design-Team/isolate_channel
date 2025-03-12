import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';
import 'package:isolate_channel/src/utils.dart';

/// A channel for receiving events from an isolate
class IsolateEventChannel {
  /// The name of the channel
  final String name;
  final IsolateConnection _connection;
  StreamSubscription? _handlerSubscription;

  /// Constructor
  IsolateEventChannel(this.name, this._connection);

  Future<void> _invokeMethod(String method, [dynamic arguments]) {
    final receivePort = ReceivePort();
    _connection
        .send(MethodInvocation(name, method, arguments, receivePort.sendPort));
    return receivePort.first;
  }

  /// Receive a broadcast stream of events from the isolate
  ///
  /// To be called from the isolate receiving events
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    if (!_connection.owner) {
      throw IsolateException(
        code: 'not_owner',
        message: 'Only the channel owner can receive events',
      );
    }
    late final StreamController controller;
    late final StreamSubscription subscription;
    controller = StreamController<dynamic>.broadcast(
      onListen: () async {
        subscription =
            _connection.receive.methodInvocations(name).listen((message) {
          final reply = message.arguments;
          if (message.method == 'endOfStream') {
            controller.close();
          } else if (reply is IsolateException) {
            controller.addError(reply);
          } else {
            controller.add(reply);
          }
        });

        await _invokeMethod('listen', arguments);
      },
      onCancel: () async {
        unawaited(subscription.cancel());
        await _invokeMethod('cancel', arguments);
      },
    );
    return controller.stream;
  }

  /// Set a handler to set up stream handling
  ///
  /// To be called from the isolate sending events
  void setStreamHandler(IsolateStreamHandler? handler) {
    if (_connection.owner) {
      throw IsolateException(
        code: 'owner',
        message: 'The channel owner cannot send events',
      );
    }

    _handlerSubscription?.cancel();
    if (handler == null) return;

    _handlerSubscription =
        _connection.receive.methodInvocations(name).listen((message) {
      switch (message.method) {
        case 'listen':
          handler.onListen(
            message.arguments,
            IsolateEventSink(name, _connection),
          );
        case 'cancel':
          handler.onCancel(message.arguments);
          _handlerSubscription?.cancel();
      }
      message.sendPort?.send(null);
    });
  }
}

/// Typedef for the inline onListen callback
typedef IsolateStreamHandlerOnListen = void Function(
  dynamic arguments,
  IsolateEventSink events,
);

/// Typedef for the inline onCancel callback
typedef IsolateStreamHandlerOnCancel = void Function(dynamic arguments);

/// A handler for setting up stream handling
abstract class IsolateStreamHandler {
  /// Called when the stream is listened to
  void onListen(dynamic arguments, IsolateEventSink events);

  /// Called when the stream is canceled
  void onCancel(dynamic arguments);

  /// Constructor
  const IsolateStreamHandler();

  /// Create an inline handler
  factory IsolateStreamHandler.inline({
    required IsolateStreamHandlerOnListen onListen,
    IsolateStreamHandlerOnCancel? onCancel,
  }) =>
      _InlineIsolateStreamHandler(onListen: onListen, onCancel: onCancel);
}

class _InlineIsolateStreamHandler extends IsolateStreamHandler {
  final IsolateStreamHandlerOnListen _onListenInline;
  final IsolateStreamHandlerOnCancel? _onCancelInline;

  _InlineIsolateStreamHandler({
    required IsolateStreamHandlerOnListen onListen,
    IsolateStreamHandlerOnCancel? onCancel,
  })  : _onListenInline = onListen,
        _onCancelInline = onCancel;

  @override
  void onListen(dynamic arguments, IsolateEventSink events) =>
      _onListenInline(arguments, events);

  @override
  void onCancel(dynamic arguments) => _onCancelInline?.call(arguments);
}

/// A sink for sending events to the stream
class IsolateEventSink {
  /// Create a new [IsolateEventSink] with the given [SendPort].
  IsolateEventSink(this._channelName, this._connection);

  final String _channelName;
  final IsolateConnection _connection;

  void _sendEvent(String method, [dynamic arguments]) {
    _connection.send(MethodInvocation(_channelName, method, arguments, null));
  }

  /// Send a success event.
  void success(Object? event) => _sendEvent('', event);

  /// Send an error event.
  void error({required String code, String? message, Object? details}) =>
      _sendEvent(
        '',
        IsolateException(code: code, message: message, details: details),
      );

  /// Send an end of stream event.
  void endOfStream() => _sendEvent('endOfStream');
}
