// core/errors/failures.dart
/// Clase base para todos los errores (failures) de la aplicación.
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Error genérico del servidor (HTTP 5xx, problemas de red, etc.)
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Error de autenticación (credenciales inválidas, token expirado)
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Error durante la verificación del código SMS
class VerificationFailure extends Failure {
  const VerificationFailure(super.message);
}

/// Error relacionado con la suscripción (prueba expirada, suscripción inactiva)
class SubscriptionFailure extends Failure {
  const SubscriptionFailure(super.message);
}

/// Error al consumir la API de Recope
class RecopeFailure extends Failure {
  const RecopeFailure(super.message);
}

/// Error al procesar la notificación (no se pudo extraer datos del viaje)
class NotificationParseFailure extends Failure {
  const NotificationParseFailure(super.message);
}

/// Error de permisos (overlay, notificaciones, etc.)
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Error al almacenar datos localmente (Flutter Secure Storage, Shared Preferences, etc.)
class LocalStorageFailure extends Failure {
  const LocalStorageFailure(super.message);
}