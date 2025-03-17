import 'package:isolate_channel/isolate_channel.dart';
import 'package:standard_message_codec/standard_message_codec.dart';

/// Extension on [Stream]
extension StreamExtension on Stream {
  static final _codec = StandardMessageCodec();

  /// Handle deserialization of invocation results
  Stream<Object?> get mapResults => map((result) {
        result = _codec.decodeMessage(result);

        final error = IsolateException.fromJson(result);
        if (error != null) {
          return error;
        }
        return result;
      });
}
