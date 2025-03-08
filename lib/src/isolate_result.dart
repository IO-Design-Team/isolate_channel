import 'dart:isolate';

class IsolateResult {
  final SendPort _sendPort;

  IsolateResult(this._sendPort);

  void call(Object? result) => _sendPort.send(result);
}
