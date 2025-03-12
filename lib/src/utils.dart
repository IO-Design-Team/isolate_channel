import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// Extension on [Stream]
extension StreamExtension on Stream {
  /// Filter by type
  Stream<T> whereType<T>() {
    return where((message) => message is T).cast<T>();
  }

  /// Filter the stream for method invocations for a [channel]
  Stream<MethodInvocation> methodInvocations(String channel) {
    return whereType<MethodInvocation>()
        .where((message) => message.channel == channel);
  }
}
