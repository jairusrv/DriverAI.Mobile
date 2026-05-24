import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String phoneNumber;
  final String email;
  final String username;
  final bool isPhoneVerified;
  final DateTime? trialEndDate;
  final bool isSubscriptionActive;
  final DateTime? subscriptionExpiryDate;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    required this.email,
    required this.username,
    required this.isPhoneVerified,
    this.trialEndDate,
    required this.isSubscriptionActive,
    this.subscriptionExpiryDate,
  });

  @override
  List<Object?> get props => [id, phoneNumber];
}