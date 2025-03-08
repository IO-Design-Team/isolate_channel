/// A method call from one isolate to another
class IsolateMethodCall {
  /// The method to invoke
  final String method;

  /// The arguments to pass to the method
  final dynamic arguments;

  /// Constructor
  const IsolateMethodCall(this.method, this.arguments);
}
