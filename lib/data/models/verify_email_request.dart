class VerifyEmailRequest {
  final String email;
  final String code;

  VerifyEmailRequest({required this.email, required this.code});

  Map<String, dynamic> toJson() => {'email': email, 'code': code};
}
