import 'dart:async';
import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'entrypoint/event_channel.dart/events.dart';
import 'entrypoint/event_channel.dart/throws.dart';

void main() async {
  await testIsolateConnection(
      eventsEntryPoint, 'event_channel.dart/events.dart', (connection) {
    final channel = IsolateEventChannel('test', connection);

    test('event channel listen', () {
      final stream = channel.receiveBroadcastStream();
      expect(
        stream,
        emitsInOrder([
          'Hello',
          null,
          emitsError(
            isAIsolateException(
              code: 'code',
              message: 'message',
              details: 'details',
            ),
          ),
          emitsDone,
        ]),
      );
    });
  });

  await testIsolateConnection(
      throwsEntryPoint, 'event_channel.dart/throws.dart', (connection) {
    final channel = IsolateEventChannel('test', connection);
    test('event channel onListen throws exception', () {
      expect(
        channel.receiveBroadcastStream().drain(),
        throwsIsolateException(
          code: 'unhandled_exception',
          message: contains('test#listen'),
          details: contains('oops'),
        ),
      );
    });
  });

  test('multiple listeners', () async {
    final receivePort = ReceivePort();
    final connection = IsolateConnection(
      send: receivePort.sendPort,
      receive: receivePort.asBroadcastStream(),
      close: () {},
    );

    final channel = IsolateEventChannel('test', connection);

    final testController = StreamController();
    channel.setStreamHandler(
      IsolateStreamHandler.inline(
        onListen: (arguments, sink) =>
            testController.add('onListen: $arguments'),
        onCancel: (arguments) => testController.add('onCancel: $arguments'),
      ),
    );

    expect(
      testController.stream,
      emitsInOrder([
        'onListen: 1',
        'onCancel: 1',
        'onListen: 2',
        'onCancel: 2',
      ]),
    );

    final stream1 = channel.receiveBroadcastStream('1');
    final subscription1 = stream1.listen((event) {});
    await subscription1.cancel();

    final stream2 = channel.receiveBroadcastStream('2');
    final subscription2 = stream2.listen((event) {});
    await subscription2.cancel();
  });

  test('multiple cancellations', () async {
    final receivePort = ReceivePort();
    final connection = IsolateConnection(
      send: receivePort.sendPort,
      receive: receivePort.asBroadcastStream(),
      close: () {},
    );

    final channel = IsolateEventChannel('test', connection);

    final testController = StreamController();
    channel.setStreamHandler(
      IsolateStreamHandler.inline(
        onListen: (arguments, sink) => testController.add('onListen'),
        onCancel: (arguments) => testController.add('onCancel'),
      ),
    );

    expect(
      testController.stream,
      emitsInOrder([
        'onListen',
        'onCancel',
        'onListen',
        'onCancel',
      ]),
    );

    final stream = channel.receiveBroadcastStream();
    final subscription1 = stream.listen((event) {});
    await subscription1.cancel();

    final subscription2 = stream.listen((event) {});
    await subscription2.cancel();
  });
}
