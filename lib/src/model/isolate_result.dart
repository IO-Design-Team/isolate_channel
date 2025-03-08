import 'dart:isolate';

/// A result from an isolate method call
class IsolateResult {
  final SendPort _sendPort;

  /// Constructor
  const IsolateResult(this._sendPort);

  /// Send a result to the sender
  void call(Object? result) => _sendPort.send(result);
}
