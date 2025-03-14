import 'dart:async';
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
      connection.close();
    });

    test('connect to isolate', () async {
      late final SendPort send;
      final connection1 = await spawnIsolate(
        isolate1EntryPoint,
        onConnect: (port) => send = port,
      );
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
      await connection1.receive.take(2).drain();
      connection2.close();
      await connection1.receive.first;
      connection1.close();
    });

    test('onExit', () async {
      final completer = Completer<void>();

      await spawnIsolate(
        (send) {
          setupIsolate(send);
          Isolate.current.kill();
        },
        onExit: completer.complete,
      );

      expect(completer.future, completes);
    });

    test('onError', () async {
      final exitCompleter = Completer<void>();
      final errorCompleter = Completer<(String, StackTrace)>();

      await spawnIsolate(
        (send) {
          setupIsolate(send);
          throw 1234;
        },
        onExit: exitCompleter.complete,
        onError: (error, stackTrace) =>
            errorCompleter.complete((error, stackTrace)),
      );

      expect(exitCompleter.future, completes);

      final (error, stackTrace) = await errorCompleter.future;
      expect(error, '1234');
      expect(stackTrace.toString(), isNotEmpty);
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
  connection2.close();
}
