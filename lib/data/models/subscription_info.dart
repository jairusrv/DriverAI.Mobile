class SubscriptionInfo {
  final bool hasAccess;
  final bool isInTrial;
  final int remainingTrialDays;
  final int remainingDays;
  final bool isSubscriptionActive;
  final DateTime? trialEndDate;
  final DateTime? subscriptionExpiryDate;
  final String? referralCode;
  final String? referredByCode;
  final int referralPaidCount;
  final int referralRewardCount;
  final int referralsNeededForReward;
  final String? lastReferralRewardMessage;
  final String message;

  const SubscriptionInfo({
    required this.hasAccess,
    required this.isInTrial,
    required this.remainingTrialDays,
    required this.remainingDays,
    required this.isSubscriptionActive,
    required this.trialEndDate,
    required this.subscriptionExpiryDate,
    required this.referralCode,
    required this.referredByCode,
    required this.referralPaidCount,
    required this.referralRewardCount,
    required this.referralsNeededForReward,
    required this.lastReferralRewardMessage,
    required this.message,
  });

  factory SubscriptionInfo.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);

    final remainingTrialDays = _parseInt(
      data['remainingTrialDays'],
    );

    final remainingDays = _parseInt(
      data['remainingDays'] ?? data['remainingAccessDays'],
      fallback: remainingTrialDays,
    );

    return SubscriptionInfo(
      hasAccess: data['hasAccess'] == true,
      isInTrial: data['isInTrial'] == true,
      remainingTrialDays: remainingTrialDays,
      remainingDays: remainingDays,
      isSubscriptionActive: data['isSubscriptionActive'] == true,
      trialEndDate: _parseDate(data['trialEndDate']),
      subscriptionExpiryDate: _parseDate(
        data['subscriptionExpiryDate'],
      ),
      referralCode: data['referralCode']?.toString(),
      referredByCode: data['referredByCode']?.toString(),
      referralPaidCount: _parseInt(data['referralPaidCount']),
      referralRewardCount: _parseInt(data['referralRewardCount']),
      referralsNeededForReward: _parseInt(
        data['referralsNeededForReward'],
        fallback: 5,
      ),
      lastReferralRewardMessage: data['lastReferralRewardMessage']?.toString(),
      message: data['message']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;

    if (value is int) return value;

    if (value is double) return value.toInt();

    return int.tryParse(value.toString()) ?? fallback;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}
