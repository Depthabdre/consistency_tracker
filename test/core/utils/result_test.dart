import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/core/errors/failures.dart';
import 'package:consistency_tracker/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Success should hold data and indicate success', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, equals(42));
      expect(result.failure, isNull);
    });

    test('Failure should hold failure and indicate failure', () {
      const failure = CacheFailure('Failed to load local storage');
      const result = Result<int>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.failure, equals(failure));
      expect(result.data, isNull);
    });

    test('fold should execute onSuccess when Result is Success', () {
      const result = Result<String>.success('hello');
      final output = result.fold(
        onSuccess: (data) => data.toUpperCase(),
        onFailure: (failure) => 'error',
      );

      expect(output, equals('HELLO'));
    });

    test('fold should execute onFailure when Result is Failure', () {
      const failure = CacheFailure('Error message');
      const result = Result<String>.failure(failure);
      final output = result.fold(
        onSuccess: (data) => data.toUpperCase(),
        onFailure: (fail) => fail.message,
      );

      expect(output, equals('Error message'));
    });
  });
}
