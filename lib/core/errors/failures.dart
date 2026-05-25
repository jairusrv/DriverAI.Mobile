abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class VerificationFailure extends Failure {
  const VerificationFailure(super.message);
}

class SubscriptionFailure extends Failure {
  const SubscriptionFailure(super.message);
}

class RecopeFailure extends Failure {
  const RecopeFailure(super.message);
}

class NotificationParseFailure extends Failure {
  const NotificationParseFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure(super.message);
}

class DeviceAlreadyExistsFailure extends Failure {
  final Map<String, dynamic>? data;
  const DeviceAlreadyExistsFailure(String message, {this.data}) : super(message);
}