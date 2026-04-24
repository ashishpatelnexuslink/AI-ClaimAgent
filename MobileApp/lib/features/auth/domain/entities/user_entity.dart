import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isVerified;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [id, fullName, email, phone, avatarUrl, role, isVerified];
}
