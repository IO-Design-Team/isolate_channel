import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:isolate_channel/src/model/internal/method_invocation.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:test/test.dart';

Matcher isAMethodInvocation(String channel, String method) {
  return isA<MethodInvocation>()
      .having((invocation) => invocation.channel, 'channel', channel)
      .having((invocation) => invocation.method, 'method', method);
}

const channel = '_isolate_channel.IsolateConnection';
const sendPortName = 'send_port';

void main() {
  group('utils', () {
    tearDown(() => IsolateNameServer.removePortNameMapping(sendPortName));

    test('spawn and setup isolate', () async {
      final connection = await spawnIsolate(isolateEntryPoint);
      final stream = connection.methodInvocations(channel);
      expect(
        stream,
        emitsInOrder([
          mayEmit(isAMethodInvocation(channel, 'addOnExitListener')),
          mayEmit(isAMethodInvocation(channel, 'addErrorListener')),
          isAMethodInvocation(channel, 'Hello'),
          emitsDone,
        ]),
      );
      connection.invoke(channel, 'Hello', null);
      // Wait for the messages to be received
      await Future.delayed(const Duration(milliseconds: 100));
      connection.close();
    });

    test('connect to isolate', () async {
      final connection1 = await spawnIsolate(isolateEntryPoint);
      final stream = connection1.methodInvocations(channel);
      stream.listen((e) => print(e.method));
      expect(
        stream,
        emitsInOrder([
          mayEmit(isAMethodInvocation(channel, 'addOnExitListener')),
          mayEmit(isAMethodInvocation(channel, 'addErrorListener')),
          isAMethodInvocation(channel, 'connect'),
          isAMethodInvocation(channel, 'addOnExitListener'),
          isAMethodInvocation(channel, 'addErrorListener'),
          isAMethodInvocation(channel, 'Hello'),
          isAMethodInvocation(channel, 'disconnect'),
          emitsDone,
        ]),
      );

      final send = IsolateNameServer.lookupPortByName(sendPortName);
      if (send == null) throw StateError('Send port not found');
      final connection2 = await connectToIsolate(send);
      connection2.invoke(channel, 'Hello', null);

      // Wait for the messages to be received
      await Future.delayed(const Duration(milliseconds: 100));
      connection2.close();
      await stream.first;
      connection1.close();
    });

    test('onExit', () async {
      final completer = Completer<void>();

      await spawnIsolate(
        (send) async {
          setupIsolate(send);
          await Future.delayed(const Duration(milliseconds: 100));
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
        (send) async {
          setupIsolate(send);
          await Future.delayed(const Duration(milliseconds: 100));
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

void isolateEntryPoint(SendPort? send) {
  final connection = setupIsolate(
    send,
    onSendPortReady: (send) =>
        IsolateNameServer.registerPortWithName(send, sendPortName),
  );
  connection.methodInvocations(channel).listen(
        (invocation) => connection.invoke(
          invocation.channel,
          invocation.method,
          invocation.arguments,
        ),
      );
}
