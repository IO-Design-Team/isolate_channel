import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';
import 'package:test/test.dart';

Matcher isAMethodInvocation(String channel, String method) {
  return isA<MethodInvocation>()
      .having((invocation) => invocation.channel, 'channel', channel)
      .having((invocation) => invocation.method, 'method', method);
}

const channel = '_isolate_channel.IsolateConnection';

void main() {
  group('utils', () {
    test('spawn and setup isolate', () async {
      final connection = await spawnIsolate(isolateEntryPoint);
      final stream = connection.methodInvocations(channel);
      expect(
        stream,
        emitsInOrder([
          isAMethodInvocation(channel, 'Hello'),
          emitsDone,
        ]),
      );
      connection.invoke(channel, 'Hello', null);
      // Wait for the message to be received
      await stream.first;
      connection.close();
    });

    test('connect to isolate', () async {
      late final SendPort send;
      final connection1 = await spawnIsolate(
        isolateEntryPoint,
        onConnect: (port) => send = port,
      );

      final connection2 = connectToIsolate(send);
      connection2.invoke(channel, 'Hello', null);

      final stream = connection1.methodInvocations(channel);
      expect(
        stream,
        emitsInOrder([
          isAMethodInvocation(channel, 'connect'),
          isAMethodInvocation(channel, 'Hello'),
          isAMethodInvocation(channel, 'disconnect'),
          emitsDone,
        ]),
      );

      // Wait for the messages to be received
      await stream.take(2).drain();
      connection2.close();
      await stream.first;
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

void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);
  connection.methodInvocations(channel).listen(
        (invocation) => connection.invoke(
          invocation.channel,
          invocation.method,
          invocation.arguments,
        ),
      );
}
