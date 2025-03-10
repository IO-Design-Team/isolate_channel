// Mocks generated by Mockito 5.4.5 from annotations
// in isolate_channel/test/common.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:isolate_channel/src/model/isolate_connection.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [IsolateConnection].
///
/// See the documentation for Mockito's code generation for more information.
class MockIsolateConnection extends _i1.Mock implements _i2.IsolateConnection {
  @override
  bool get owner =>
      (super.noSuchMethod(
            Invocation.getter(#owner),
            returnValue: false,
            returnValueForMissingStub: false,
          )
          as bool);

  @override
  _i3.Stream<dynamic> get receive =>
      (super.noSuchMethod(
            Invocation.getter(#receive),
            returnValue: _i3.Stream<dynamic>.empty(),
            returnValueForMissingStub: _i3.Stream<dynamic>.empty(),
          )
          as _i3.Stream<dynamic>);

  @override
  int get connections =>
      (super.noSuchMethod(
            Invocation.getter(#connections),
            returnValue: 0,
            returnValueForMissingStub: 0,
          )
          as int);

  @override
  void send(Object? message) => super.noSuchMethod(
    Invocation.method(#send, [message]),
    returnValueForMissingStub: null,
  );

  @override
  void shutdown() => super.noSuchMethod(
    Invocation.method(#shutdown, []),
    returnValueForMissingStub: null,
  );
}
