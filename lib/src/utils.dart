import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// Extension on [Stream]
extension StreamExtension on Stream {
  /// Filter the stream for method invocations for a channel [name]
  Stream<MethodInvocation> methodInvocations(String name) {
    return where(
      (message) => message is MethodInvocation && message.channel == name,
    ).cast<MethodInvocation>();
  }
}
