class RegisterRequest {
  final String imei;
  final String phoneNumber;
  final String email;
  final String username;
  final String password;
  final String? referralCode;

  RegisterRequest({
    required this.imei,
    required this.phoneNumber,
    required this.email,
    required this.username,
    required this.password,
    this.referralCode,
  });

  Map<String, dynamic> toJson() => {
        'imei': imei,
        'phoneNumber': phoneNumber,
        'email': email,
        'username': username,
        'password': password,
        if (referralCode != null && referralCode!.trim().isNotEmpty)
          'referralCode': referralCode!.trim().toUpperCase(),
      };
}