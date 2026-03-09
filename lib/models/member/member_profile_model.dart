import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class MemberProfileResponse extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final int groupId;
  final String groupName;
  final String address;
  final String joinDate;
  final String aadhaarMasked;

  const MemberProfileResponse({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.groupId,
    required this.groupName,
    required this.address,
    required this.joinDate,
    required this.aadhaarMasked,
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
      address: json['address'] ?? '',
      joinDate: json['join_date'] ?? '',
      aadhaarMasked: json['aadhaar_masked'] ?? '',
    );
  }

  String get formattedJoinDate {
    try {
      final d = DateTime.parse(joinDate);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return joinDate;
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        isActive,
        groupId,
        groupName,
        address,
        joinDate,
        aadhaarMasked,
      ];
}
