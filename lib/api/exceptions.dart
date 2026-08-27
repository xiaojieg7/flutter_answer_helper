class CaptchaNeedRefreshException implements Exception {
  final String message;
  
  CaptchaNeedRefreshException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class TokenExpiredException implements Exception {
  final String message;
  
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  
  UnauthorizedException(this.message);
  
  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException(this.message, [this.statusCode]);
  
  @override
  String toString() => message;
}

class DeviceNotTrustException implements Exception {
  final String message;
  final String email;
  
  DeviceNotTrustException(this.message, {required this.email});
  
  @override
  String toString() => message;
}
