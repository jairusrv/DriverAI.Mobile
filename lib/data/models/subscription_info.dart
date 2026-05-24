import 'package:equatable/equatable.dart';

class SubscriptionInfo extends Equatable {
  final bool hasAccess;
  final bool isInTrial;
  final int remainingTrialDays;
  final bool isSubscriptionActive;
  final DateTime? subscriptionExpiryDate;
  final String? message;

  const SubscriptionInfo({
    required this.hasAccess,
    required this.isInTrial,
    required this.remainingTrialDays,
    required this.isSubscriptionActive,
    this.subscriptionExpiryDate,
    this.message,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      hasAccess: json['hasAccess'] as bool,
      isInTrial: json['isInTrial'] as bool,
      remainingTrialDays: json['remainingTrialDays'] as int,
      isSubscriptionActive: json['isSubscriptionActive'] as bool,
      subscriptionExpiryDate: json['subscriptionExpiryDate'] != null
          ? DateTime.parse(json['subscriptionExpiryDate'])
          : null,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        hasAccess,
        isInTrial,
        remainingTrialDays,
        isSubscriptionActive,
        subscriptionExpiryDate,
        message,
      ];
}