import 'dart:io';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

@GenerateNiceMocks([MockSpec<IsolateConnection>()])
import 'common.mocks.dart';

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

Matcher throwsIsolateException({
  required Object code,
  Object? message,
  Object? details,
}) {
  return throwsA(
    isAIsolateException(code: code, message: message, details: details),
  );
}

MockIsolateConnection createConnection({
  int connections = 1,
}) {
  final connection = MockIsolateConnection();
  when(connection.connections).thenReturn(connections);
  return connection;
}

Future<IsolateConnection> spawn({
  IsolateEntryPoint? entryPoint,
  String? entryPointFile,
}) {
  assert(entryPoint != null || entryPointFile != null);
  if (entryPoint != null) {
    return spawnIsolate(entryPoint);
  }
  return spawnUriIsolate(
    Uri.file('${Directory.current.path}/test/entrypoint/$entryPointFile'),
  );
}

Future<void> testIsolateConnection(
  IsolateEntryPoint entryPoint,
  String entryPointFile,
  void Function(IsolateConnection) test,
) async {
  final connection1 = await spawn(entryPoint: entryPoint);

  group('Isolate.spawn', () {
    tearDownAll(connection1.close);
    test(connection1);
  });

  final connection2 = await spawn(entryPointFile: entryPointFile);
  group('Isolate.spawnUri', () {
    tearDownAll(connection2.close);
    test(connection2);
  });
}
