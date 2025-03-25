import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// A channel for receiving events from an isolate
class IsolateEventChannel {
  static const _endOfStream = '_isolate_channel.endOfStream';

  /// The name of the channel
  final String name;
  final IsolateConnection _connection;
  StreamSubscription? _handlerSubscription;

  /// Constructor
  IsolateEventChannel(this.name, this._connection);

  /// Receive a broadcast stream of events from the isolate
  ///
  /// To be called from the isolate receiving events
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    final receivePort = ReceivePort();
    final receive = receivePort.asBroadcastStream();

    late final StreamController controller;
    StreamSubscription? subscription;

    controller = StreamController<dynamic>.broadcast(
      onListen: () {
        _connection.invoke(name, 'listen', arguments, receivePort.sendPort);

        subscription = receive.mapResults.listen((event) {
          if (event == _endOfStream) {
            controller.close();
            subscription?.cancel();
            receivePort.close();
            return;
          }

          if (event is IsolateException) {
            controller.addError(event);
          } else {
            controller.add(event);
          }
        });
      },
      onCancel: () {
        _connection.invoke(name, 'cancel', arguments);
        subscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Set a handler to set up stream handling
  ///
  /// To be called from the isolate sending events
  void setStreamHandler(IsolateStreamHandler? handler) {
    _handlerSubscription?.cancel();
    if (handler == null) return;

    _handlerSubscription =
        _connection.methodInvocations(name).listen((invocation) {
      try {
        switch (invocation.method) {
          case 'listen':
            handler.onListen(
              invocation.arguments,
              IsolateEventSink(invocation),
            );
          case 'cancel':
            handler.onCancel(invocation.arguments);
        }
      } catch (error, stackTrace) {
        invocation.unhandled(error, stackTrace);
      }
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
      _InlineIsolateStreamHandler(onListen, onCancel);
}

class _InlineIsolateStreamHandler extends IsolateStreamHandler {
  final IsolateStreamHandlerOnListen _onListen;
  final IsolateStreamHandlerOnCancel? _onCancel;

  const _InlineIsolateStreamHandler(
    IsolateStreamHandlerOnListen onListen,
    IsolateStreamHandlerOnCancel? onCancel,
  )   : _onListen = onListen,
        _onCancel = onCancel;

  @override
  void onListen(dynamic arguments, IsolateEventSink events) =>
      _onListen(arguments, events);

  @override
  void onCancel(dynamic arguments) => _onCancel?.call(arguments);
}

/// A sink for sending events to the stream
class IsolateEventSink {
  final MethodInvocation _invocation;

  /// Constructor
  const IsolateEventSink(this._invocation);

  /// Send a success event.
  void success(Object? event) => _invocation.result(event);

  /// Send an error event.
  void error({required String code, String? message, Object? details}) =>
      _invocation.result(
        IsolateException(code: code, message: message, details: details),
      );

  /// Send an end of stream event.
  void endOfStream() => _invocation.result(IsolateEventChannel._endOfStream);
}
