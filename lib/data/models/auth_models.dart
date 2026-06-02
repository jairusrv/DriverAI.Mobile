/// Request de registro
class RegisterRequest {
  final String phoneNumber; // 8 dígitos
  final String email;
  final String username;
  final String password;

  RegisterRequest({
    required this.phoneNumber,
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'email': email,
        'username': username,
        'password': password,
      };
}

/// Request de login
class LoginRequest {
  final String phoneNumber; // 8 dígitos
  final String password;

  LoginRequest({required this.phoneNumber, required this.password});

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'password': password,
      };
}

/// Request de verificación de código
class VerifyCodeRequest {
  final String phoneNumber; // 8 dígitos
  final String code;

  VerifyCodeRequest({required this.phoneNumber, required this.code});

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'code': code,
      };
}

/// Request de reenvío de código
class ResendCodeRequest {
  final String phoneNumber;

  ResendCodeRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};
}
