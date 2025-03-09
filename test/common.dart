import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';
import 'package:test/test.dart';

Matcher isAIsolateException({
  required String code,
  String? message,
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

Matcher isAMethodInvocation({
  required String name,
  required String method,
  dynamic arguments,
}) => isA<MethodInvocation>()
    .having((e) => e.name, 'name', name)
    .having((e) => e.method, 'method', method)
    .having((e) => e.arguments, 'arguments', arguments);
