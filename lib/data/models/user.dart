import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String phoneNumber;
  final String email;
  final String username;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.email,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phoneNumber:
          json['phoneNumber'] as String? ?? json['phoneNumber'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
    );
  }

  @override
  List<Object?> get props => [id, phoneNumber, email, username];
}
