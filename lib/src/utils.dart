import 'package:isolate_channel/src/model/internal/method_invocation.dart';

/// Extension on [Stream]
extension StreamExtension on Stream {
  /// Map null results to null
  Stream<Object?> get mapNulls =>
      map((message) => message == MethodInvocation.nullResult ? null : message);
}
