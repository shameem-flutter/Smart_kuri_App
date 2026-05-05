import 'package:equatable/equatable.dart';

class Member extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final int groupId;
  final String groupName;
  final String address;
  final String aadhaarNo;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.groupId,
    required this.groupName,
    required this.address,
    required this.aadhaarNo,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      groupId: int.tryParse(json['group_id'].toString()) ?? 0,
      groupName: json['group_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      aadhaarNo:
          (json['aadhaar_no'] ??
                  json['aadhar_no'] ??
                  json['aadhaar_number'] ??
                  json['aadhar_number'] ??
                  json['aadhaar'] ??
                  json['aadhar'])
              ?.toString() ??
          '',
    );
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
    aadhaarNo,
  ];
}

class MemberListResponse extends Equatable {
  final int count;
  final List<Member> results;

  const MemberListResponse({required this.count, required this.results});

  factory MemberListResponse.fromJson(Map<String, dynamic> json) {
    return MemberListResponse(
      count: int.tryParse(json['count'].toString()) ?? 0,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => Member.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [count, results];
}
