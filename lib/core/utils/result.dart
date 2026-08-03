import '../errors/failures.dart';

class Result<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;

  const Result.success(this.data)
      : failure = null,
        isSuccess = true;

  const Result.failure(this.failure)
      : data = null,
        isSuccess = false;

  bool get isFailure => !isSuccess;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onFailure(failure!);
    }
  }
}
