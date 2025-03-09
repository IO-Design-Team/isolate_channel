import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import '../common.dart';

bool register(IsolateConnection connection) =>
    connection.registerPortWithName('', (_, _) => true);

void main() {
  group('isolate connection', () {
    test('registerPortWithName', () async {
      final connection1 = await spawnIsolate(setupIsolate);
      expect(register(connection1), true);

      final connection2 = connectToIsolate(ReceivePort().sendPort);
      expect(register(connection2), true);

      final connection3 = setupIsolate(ReceivePort().sendPort);
      expect(
        () => register(connection3),
        throwsA(isAIsolateException(code: 'not_owner')),
      );
    });
  });
}
