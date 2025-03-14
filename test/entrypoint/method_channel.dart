import 'dart:isolate';

import '../isolate_method_channel_test.dart';

@pragma('vm:entry-point')
void main(List<String> args, SendPort send) => isolateEntryPoint(send);
