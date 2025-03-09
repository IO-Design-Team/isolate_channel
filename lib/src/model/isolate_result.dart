import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';

/// A result from an isolate method call
class IsolateResult {
  final SendPort _sendPort;

  /// Constructor
  const IsolateResult(this._sendPort);

  /// Send a result to the sender
  void call(Object? result) => _sendPort.send(result);

  /// Inform the caller the the method is not implemented
  void notImplemented() =>
      _sendPort.send(IsolateException(code: 'not_implemented'));
}
