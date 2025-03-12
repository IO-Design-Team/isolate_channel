import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() {
  test('isolate exception', () {
    final exception =
        IsolateException(code: 'code', message: 'message', details: 'details');
    expect(
      exception.toString(),
      'IsolateException(code: code, message: message, details: details)',
    );
  });
}
