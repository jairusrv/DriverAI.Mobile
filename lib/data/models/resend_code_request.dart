// data/models/resend_code_request.dart
class ResendCodeRequest {
  final String phoneNumber;

  ResendCodeRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};
}
