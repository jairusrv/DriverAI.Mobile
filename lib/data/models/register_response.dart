// data/models/register_response.dart
class RegisterResponse {
  final String phoneNumber;
  final String countryCode;
  final DateTime trialEndDate;
  final int freeTrialDays;
  final bool requiresSmsVerification;

  RegisterResponse({
    required this.phoneNumber,
    required this.countryCode,
    required this.trialEndDate,
    required this.freeTrialDays,
    required this.requiresSmsVerification,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      phoneNumber: json['phoneNumber'] as String,
      countryCode: json['countryCode'] as String,
      trialEndDate: DateTime.parse(json['trialEndDate']),
      freeTrialDays: json['freeTrialDays'] as int,
      requiresSmsVerification: json['requiresSmsVerification'] as bool,
    );
  }
}
