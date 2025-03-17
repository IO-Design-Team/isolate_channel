## 0.2.0

- BREAKING: Can no longer send null values over an event channel (URI isolates do not support this)
- BREAKING: Refactors `IsolateException.notImplemented()` into `call.notImplemented()`
- Supports communication between isolates spawned with `Isolate.spawnUri`
- EventChannel optimizations

## 0.1.1

- Handles exceptions thrown in method call handlers

## 0.1.0

- Initial release
