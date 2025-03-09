import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() {
  group('utils', () {
    test('spawn and setup isolate', () async {
      final (send, receive, shutdown) = await spawnIsolate((send) {
        final receive = setupIsolate(send);
        receive.listen(send.send);
      });
      expect(receive, emitsInOrder(['Hello', emitsDone]));
      send.send('Hello');
      await receive.first;
      shutdown();
    });

    test('connect to isolate', () async {
      final (send, receive, shutdown) = await spawnIsolate((send) {
        final receive = setupIsolate(send);
        receive.listen(send.send);
      });
      await Isolate.run(() => isolateEntryPoint(send));
    });
  });
}

Future<void> isolateEntryPoint(SendPort sendPort) async {
  final (send, receive, shutdown) = await connectToIsolate(sendPort);
}
