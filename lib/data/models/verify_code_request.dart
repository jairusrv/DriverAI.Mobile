class VerifyCodeRequest {
  final String phoneNumber;
  final String code;

  VerifyCodeRequest({required this.phoneNumber, required this.code});

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'code': code,
      };
}