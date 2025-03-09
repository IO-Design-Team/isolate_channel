import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/connection_message.dart';
import 'package:test/test.dart';

void main() {
  group('utils', () {
    test('spawn and setup isolate', () async {
      final connection = await spawnIsolate(isolate1EntryPoint);
      expect(connection.receive, emitsInOrder(['Hello', emitsDone]));
      connection.send('Hello');
      // Wait for the message to be received
      await connection.receive.first;
      connection.shutdown();
    });

    test('connect to isolate', () async {
      final connection1 = await spawnIsolate(isolate1EntryPoint);
      late final SendPort send;
      connection1.registerPortWithName('test', (port, name) {
        send = port;
        return true;
      });
      final connection2 = await spawnIsolate(isolate2EntryPoint);
      connection2.send(send);
      expect(
        connection1.receive,
        emitsInOrder([
          isA<IsolateConnect>(),
          'Hello',
          isA<IsolateDisconnect>(),
          emitsDone,
        ]),
      );
      // Wait for the messages to be received
      await connection1.receive.take(2).toList();
      connection2.shutdown();
      await connection1.receive.first;
      connection1.shutdown();
    });
  });
}

void isolate1EntryPoint(SendPort send) {
  final connection = setupIsolate(send);
  connection.receive.listen(connection.send);
}

void isolate2EntryPoint(SendPort send) async {
  final connection1 = setupIsolate(send);
  final send2 = await connection1.receive.first;
  final connection2 = connectToIsolate(send2);
  connection2.send('Hello');
  connection2.shutdown();
}
