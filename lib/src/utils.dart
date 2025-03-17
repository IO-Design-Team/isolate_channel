import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// Extension on [Stream]
extension StreamExtension on Stream {
  /// Handle deserialization of invocation results
  Stream<Object?> get mapResults => map((result) {
        if (result == MethodInvocation.nullResult) {
          return null;
        }

        final error = IsolateException.fromJson(result);
        if (error != null) {
          return error;
        }
        return result;
      });
}
