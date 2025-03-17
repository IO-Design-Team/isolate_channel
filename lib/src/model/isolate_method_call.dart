import 'package:isolate_channel/src/model/isolate_exception.dart';

/// A method call from one isolate to another
class IsolateMethodCall {
  /// The name of the channel
  final String _channel;

  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// Constructor
  const IsolateMethodCall(this._channel, this.method, this.arguments);

  /// Create a not implemented exception for this method call
  IsolateException notImplemented() =>
      IsolateException.notImplemented(_channel, method);
}
