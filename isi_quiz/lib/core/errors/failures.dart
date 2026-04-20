abstract class Failure {
  final String message;
  
  Failure(this.message);
  
  @override
  String toString() => 'Failure: $message';
}

class ServerFailure extends Failure {
  final String? code;
  
  ServerFailure(super.message, [this.code]);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  final String? field;
  
  ValidationFailure(super.message, [this.field]);
}
