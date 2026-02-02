## 0.6.0

- Removes `onConnect` callbacks in favor of `onSendPortReady` in `setupIsolate` to support headless restarts
- The `IsolateEntryPoint` and `setupIsolate` functions now accept a nullable `send` parameter to support headless restarts
- The `connectToIsolate` function now supports `onExit` and `onError` callback setup
- Removes the `control` parameter from `IsolateSpawner` since this is now handled internally

## 0.5.0

- Exposes the `spawnIsolateConnection` function that allows connecting to custom isolates
- Removes the `spawn` parameters from the `spawnIsolate` and `spawnUriIsolate` functions

## 0.4.2

- Updates README to reflect that `connectToIsolate` returns a `Future`

## 0.4.1

- Loosens constraint on `meta`

## 0.4.0

- Allows passing an `IsolateSpawner` to support custom isolate implementations such as `FlutterIsolate`
- Makes `connectToIsolate` return a `Future` so that connection failure can be handled

## 0.3.0

- Removes unnecessary type parameters from spawn methods

## 0.2.2+1

- Adds README badges

## 0.2.2

- Handles more edge cases in `IsolateEventChannel`

## 0.2.1

- Does not cancel handler subscription when `onCancel` is called in `IsolateEventChannel`

## 0.2.0

- BREAKING: Refactors `IsolateException.notImplemented(...)` into `call.notImplemented()`
- Supports communication between isolates spawned with `Isolate.spawnUri`
- EventChannel optimizations

## 0.1.1

- Handles exceptions thrown in method call handlers

## 0.1.0

- Initial release
