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
    final data = json as Map<String, dynamic>;

    return SubscriptionInfo(
      hasAccess: data['hasAccess'] ?? false,
      isInTrial: data['isInTrial'] ?? false,
      remainingTrialDays: data['remainingTrialDays'] ?? 0,
      remainingDays: data['remainingDays'] ?? 0,
      isSubscriptionActive: data['isSubscriptionActive'] ?? false,
      trialEndDate: _parseDate(data['trialEndDate']),
      subscriptionExpiryDate: _parseDate(
        data['subscriptionExpiryDate'],
      ),
      referralCode: data['referralCode']?.toString(),
      referredByCode: data['referredByCode']?.toString(),
      referralPaidCount: data['referralPaidCount'] ?? 0,
      referralRewardCount: data['referralRewardCount'] ?? 0,
      referralsNeededForReward:
          data['referralsNeededForReward'] ?? 5,
      lastReferralRewardMessage:
          data['lastReferralRewardMessage']?.toString(),
      message: data['message']?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}