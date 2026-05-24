class ApiConstants {
  static const String baseUrl = 'https://driverai-api.onrender.com';
  static const String register = '/api/auth/register';
  static const String verifyCode = '/api/auth/verify-code';
  static const String resendCode = '/api/auth/resend-code';
  static const String login = '/api/auth/login';
  static const String subscriptionStatus = '/api/auth/subscription-status';
  static const String activateSubscription = '/api/auth/activate-subscription';
  static const String recopeData = '/api/recope/datos';
  static const String recopeUpdate = '/api/recope/actualizar';
  static const int defaultTimeout = 30;
}