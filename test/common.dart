import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

Matcher isAIsolateException({
  required Object code,
  Object? message,
  Object? details,
}) {
  var matcher = isA<IsolateException>().having((e) => e.code, 'code', code);
  if (message != null) {
    matcher = matcher.having((e) => e.message, 'message', message);
  }
  if (details != null) {
    matcher = matcher.having((e) => e.details, 'details', details);
  }
  return matcher;
}
