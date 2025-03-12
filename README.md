Communication channels for isolates based on Flutter's plugin channels

## Features

- Helper functions to spawn, setup, and connect to isolates
- Method channels for making method calls to an isolate and receiving the result
- Event channels for receiving streamed events from an isolate

## Usage

In the parent isolate, use the `spawnIsolate` function to spawn a new isolate and connect to it

```dart
final connection = await spawnIsolate(isolateEntryPoint);
```

In the newly spawned isolate, use the `setupIsolate` function to set up the isolate for channel communication

```dart
void isolateEntryPoint(SendPort send) {
  final connection = setupIsolate(send);
}
```

Now create communication channels in both isolates

```dart
final methodChannel = IsolateMethodChannel('method_channel', connection);
final eventChannel = IsolateEventChannel('event_channel', connection);
```

Set up handlers for the channels in the newly spawned isolate

```dart
methodChannel.setMethodCallHandler((call) {
  switch (call.method) {
    case 'example_method':
      print(call.arguments);
      return 'World!';
    default:
      return IsolateException.notImplemented(call.method);
  }
});

eventChannel.setStreamHandler(
  IsolateStreamHandler.inline(
    onListen: (arguments, sink) {
      sink.success(arguments);
      sink.error(
        code: 'error',
        message: 'Something went wrong',
        details: 1234,
      );
      sink.endOfStream();
    },
    onCancel: (arguments) => print('Canceled: $arguments'),
  ),
);
```

Now you can use the channels to communicate

```dart
final result = await methodChannel.invokeMethod('example_method', 'Hello');
final stream = eventChannel.receiveBroadcastStream();
```
