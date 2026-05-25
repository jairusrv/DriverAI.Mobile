class RegisterRequest {
  final String imei;
  final String phoneNumber;
  final String email;
  final String username;
  final String password;

  RegisterRequest({
    required this.imei,
    required this.phoneNumber,
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'imei': imei,
    'phoneNumber': phoneNumber,
    'email': email,
    'username': username,
    'password': password,
  };
}