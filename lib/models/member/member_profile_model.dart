import 'package:equatable/equatable.dart';

class MemberProfileResponse extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final int groupId;
  final String groupName;

  const MemberProfileResponse({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.groupId,
    required this.groupName,
  });

  factory MemberProfileResponse.fromJson(Map<String, dynamic> json) {
    return MemberProfileResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? false,
      groupId: json['group_id'] ?? 0,
      groupName: json['group_name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, phone, email, isActive, groupId, groupName];
}
