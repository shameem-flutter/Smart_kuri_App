import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class MemberDashboardResponse extends Equatable {
  final MemberDashboardInfo member;
  final double totalPaid;
  final double totalAmount;
  final double remaining;
  final List<AuctionItem> auctions;
  final AuctionItem? latestAuction;
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
      auctions: (json['auctions'] as List<dynamic>? ?? [])
          .map((e) => AuctionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestAuction: json['latest_auction'] != null
          ? AuctionItem.fromJson(json['latest_auction'] as Map<String, dynamic>)
          : null,
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
  final String address;
  final String joinDate;
  final String aadhaarMasked;

  const MemberDashboardInfo({
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

  factory MemberDashboardInfo.fromJson(Map<String, dynamic> json) {
    return MemberDashboardInfo(
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

class AuctionItem extends Equatable {
  final int id;
  final int group;
  final int monthNo;
  final String auctionDate;
  final int? winner;
  final int? winnerToken;
  final String winnerName;
  final String status;
  final String action;

  const AuctionItem({
    required this.id,
    required this.group,
    required this.monthNo,
    required this.auctionDate,
    this.winner,
    this.winnerToken,
    required this.winnerName,
    required this.status,
    required this.action,
  });

  factory AuctionItem.fromJson(Map<String, dynamic> json) {
    return AuctionItem(
      id: json['id'] ?? 0,
      group: json['group'] ?? 0,
      monthNo: json['month_no'] ?? 0,
      auctionDate: json['auction_date'] ?? '',
      winner: json['winner'],
      winnerToken: json['winner_token'],
      winnerName: json['winner_name'] ?? '',
      status: json['status'] ?? '',
      action: json['action'] ?? '',
    );
  }

  String get formattedDate {
    try {
      final d = DateTime.parse(auctionDate);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return auctionDate;
    }
  }

  bool get isCompleted => status.toLowerCase() == 'completed';

  @override
  List<Object?> get props => [
    id,
    group,
    monthNo,
    auctionDate,
    winner,
    winnerToken,
    winnerName,
    status,
    action,
  ];
}
