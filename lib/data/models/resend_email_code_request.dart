class ResendEmailCodeRequest {
  final String email;

  ResendEmailCodeRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}