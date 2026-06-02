// data/models/verify_code_response.dart
import 'user.dart';
import 'subscription_info.dart';

class VerifyCodeResponse {
  final String token;
  final User user;
  final Map<String, dynamic> subscription;

  VerifyCodeResponse({
    required this.token,
    required this.user,
    required this.subscription,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user']),
      subscription: json['subscription'] as Map<String, dynamic>,
    );
  }
}
