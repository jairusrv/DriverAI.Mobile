import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: json['errors'] != null
          ? List<String>.from(
              (json['errors'] as List).map(
                (e) => e.toString(),
              ),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        success,
        message,
        data,
        errors,
      ];
}