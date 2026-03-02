import 'package:equatable/equatable.dart';

class MemberDashboardResponse extends Equatable {
  final MemberDashboardInfo member;
  final double totalPaid;
  final double totalAmount;
  final double remaining;
  final List<dynamic> auctions; // Can be typed later if we know the structure
  final dynamic latestAuction; // Can be typed later
  final bool isWinner;

  const MemberDashboardResponse({
    required this.member,
    required this.totalPaid,
    required this.totalAmount,
    required this.remaining,
    required this.auctions,
    this.latestAuction,
    required this.isWinner,
  });

  factory MemberDashboardResponse.fromJson(Map<String, dynamic> json) {
    return MemberDashboardResponse(
      member: MemberDashboardInfo.fromJson(json['member'] ?? {}),
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      auctions: json['auctions'] as List<dynamic>? ?? [],
      latestAuction: json['latest_auction'],
      isWinner: json['is_winner'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        member,
        totalPaid,
        totalAmount,
        remaining,
        auctions,
        latestAuction,
        isWinner,
      ];
}

class MemberDashboardInfo extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final int groupId;
  final String groupName;

  const MemberDashboardInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.groupId,
    required this.groupName,
  });

  factory MemberDashboardInfo.fromJson(Map<String, dynamic> json) {
    return MemberDashboardInfo(
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
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        isActive,
        groupId,
        groupName,
      ];
}
