import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

class IsolateEventChannel {
  final String name;
  final SendPort _sendPort;
  final Stream _receivePort;

  /// Constructor
  IsolateEventChannel(this.name, this._sendPort, this._receivePort);

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

  void setStreamHandler(IsolateStreamHandler handler) {}
}

abstract class IsolateStreamHandler {
  void onListen(dynamic arguments, IsolateEventSink events);
  void onCancel(dynamic arguments);
}

class IsolateEventSink {
  /// Create a new [IsolateEventSink] with the given [sink].
  IsolateEventSink(EventSink<Object?> sink) : _sink = sink;

  final EventSink<Object?> _sink;

  /// Send a success event.
  void success(Object? event) => _sink.add(event);

  /// Send an error event.
  void error({required String code, String? message, Object? details}) =>
      _sink.addError(
        IsolateExcaption(code: code, message: message, details: details),
      );

  /// Send an end of stream event.
  void endOfStream() => _sink.close();
}

class IsolateExcaption {
  final String code;
  final String? message;
  final Object? details;

  const IsolateExcaption({required this.code, this.message, this.details});
}
