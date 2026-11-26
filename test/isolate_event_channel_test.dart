import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

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

    test('event channel transform', () {
      final stream = channel.receiveBroadcastStream(
        null,
        (event) => event == 'Hello' ? throw StateError('boom') : '$event',
      );
      expect(
        stream,
        emitsInOrder([
          emitsError(isA<StateError>()),
          'null',
          emitsError(isAIsolateException(code: 'code')),
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

  test('transform runs once per event across listeners', () async {
    final receivePort = ReceivePort();
    final connection = IsolateConnection(
      send: receivePort.sendPort,
      receive: receivePort.asBroadcastStream(),
      close: receivePort.close,
    );
    addTearDown(connection.close);

    final channel = IsolateEventChannel('test', connection);
    final sinkCompleter = Completer<IsolateEventSink>();
    channel.setStreamHandler(
      IsolateStreamHandler.inline(
        onListen: (_, sink) => sinkCompleter.complete(sink),
      ),
    );

    var calls = 0;
    final stream = channel.receiveBroadcastStream(null, (e) {
      calls++;
      return (e as TransferableTypedData).materialize().asUint8List();
    });

    final listeners = [stream.toList(), stream.toList()];

    final sink = await sinkCompleter.future;
    final data = Uint8List.fromList([1, 2, 3]);
    sink.success(TransferableTypedData.fromList([data]));
    sink.endOfStream();

    expect(await Future.wait(listeners), [
      [data],
      [data],
    ]);
    expect(calls, 1);
  });
}
