import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// Extension on [Stream]
extension StreamExtension on Stream {
  /// Filter the stream for method invocations for a [channel]
  Stream<MethodInvocation> methodInvocations(String channel) {
    return where(
      (message) => message is MethodInvocation && message.channel == channel,
    ).cast<MethodInvocation>();
  }
}
