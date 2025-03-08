import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/isolate_message.dart';

/// A channel for receiving events from an isolate
class IsolateEventChannel {
  /// The name of the channel
  final String name;
  final SendPort _sendPort;
  final Stream _receivePort;
  StreamSubscription? _handlerSubscription;

  /// Constructor
  IsolateEventChannel(this.name, this._sendPort, this._receivePort);

  /// Receive a broadcast stream of events from the isolate
  ///
  /// To be called from the isolate receiving events
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    final methodChannel = IsolateMethodChannel(name, _sendPort, _receivePort);
    late StreamController<dynamic> controller;
    controller = StreamController<dynamic>.broadcast(
      onListen: () async {
        methodChannel.setMethodCallHandler((call, result) {
          final reply = call.arguments;
          if (reply == null) {
            controller.close();
          } else if (reply is IsolateExcaption) {
            controller.addError(reply);
          } else {
            controller.add(reply);
          }
        });

        await methodChannel.invokeMethod<void>('listen', arguments);
      },
      onCancel: () async {
        methodChannel.setMethodCallHandler(null);
        await methodChannel.invokeMethod<void>('cancel', arguments);
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

    _handlerSubscription = _receivePort
        .where((message) => message is IsolateMessage && message.name == name)
        .cast<IsolateMessage>()
        .listen((message) {
          switch (message.method) {
            case 'listen':
              handler.onListen(message.arguments, IsolateEventSink(_sendPort));
            case 'cancel':
              handler.onCancel(message.arguments);
          }
        });
  }
}

/// A handler for setting up stream handling
abstract class IsolateStreamHandler {
  /// Called when the stream is listened to
  void onListen(dynamic arguments, IsolateEventSink events);

  /// Called when the stream is canceled
  void onCancel(dynamic arguments);
}

/// A sink for sending events to the stream
class IsolateEventSink {
  /// Create a new [IsolateEventSink] with the given [SendPort].
  IsolateEventSink(this._sendPort);

  final SendPort _sendPort;

  /// Send a success event.
  void success(Object? event) => _sendPort.send(event);

  /// Send an error event.
  void error({required String code, String? message, Object? details}) =>
      _sendPort.send(
        IsolateExcaption(code: code, message: message, details: details),
      );

  /// Send an end of stream event.
  void endOfStream() => _sendPort.send(null);
}

/// An exception thrown by the isolate
class IsolateExcaption {
  /// The code of the exception
  final String code;

  /// The message of the exception
  final String? message;

  /// The details of the exception
  final Object? details;

  /// Constructor
  const IsolateExcaption({required this.code, this.message, this.details});
}
