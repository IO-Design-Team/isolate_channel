import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// A channel for receiving events from an isolate
class IsolateEventChannel {
  static const _endOfStream = 'isolate_channel.IsolateEventChannel#endOfStream';

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

    void close() {
      controller.close();
      subscription?.cancel();
      receivePort.close();
    }

    controller = StreamController<dynamic>.broadcast(
      onListen: () {
        _connection.send(
          MethodInvocation(name, 'listen', arguments, receivePort.sendPort),
        );

        subscription = receive.listen((event) {
          if (event == _endOfStream) {
            close();
            return;
          }

          final error = IsolateException.fromJson(event);
          if (error != null) {
            controller.addError(error);
          } else {
            controller.add(event);
          }
        });
      },
      onCancel: () {
        close();
        _connection.send(
          MethodInvocation(name, 'cancel', arguments, receivePort.sendPort),
        );
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
        _connection.methodInvocations(name).listen((message) {
      try {
        switch (message.method) {
          case 'listen':
            handler.onListen(
              message.arguments,
              IsolateEventSink(message.sendPort!),
            );
          case 'cancel':
            handler.onCancel(message.arguments);
            _handlerSubscription?.cancel();
        }
      } catch (error, stackTrace) {
        message.sendPort?.send(
          IsolateException.unhandled(name, message.method, error, stackTrace)
              .toJson(),
        );
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
  final SendPort _send;

  /// Constructor
  const IsolateEventSink(this._send);

  /// Send a success event.
  void success(Object event) => _send.send(event);

  /// Send an error event.
  void error({required String code, String? message, Object? details}) =>
      _send.send(
        IsolateException(code: code, message: message, details: details)
            .toJson(),
      );

  /// Send an end of stream event.
  void endOfStream() => _send.send(IsolateEventChannel._endOfStream);
}
