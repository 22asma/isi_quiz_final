class ServerException implements Exception {
  final String message;
  final String? code;
  
  ServerException(this.message, [this.code]);
  
  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  
  CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  final String message;
  final String? field;
  
  ValidationException(this.message, [this.field]);
  
  @override
  String toString() => 'ValidationException: $message';
}
