class Failure {
  final String message;
  final int statusCode;

  const Failure({required this.message, this.statusCode = 500});

  @override
  String toString() => 'Failure(message: $message, statusCode: $statusCode)';
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message: message, statusCode: 500);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message: message, statusCode: 400);
}

class AuthFailure extends Failure {
  AuthFailure(String message) : super(message: message, statusCode: 401);
}

class ForbiddenFailure extends Failure {
  ForbiddenFailure(String message) : super(message: message, statusCode: 403);
}

class NotFoundFailure extends Failure {
  NotFoundFailure(String message) : super(message: message, statusCode: 404);
}
