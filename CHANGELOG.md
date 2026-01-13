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
