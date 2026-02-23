
import 'package:equatable/equatable.dart';

class GroupDetail extends Equatable {
  final int id;
  final String name;
  final double monthlyAmount;
  final int durationMonths;
  final double totalAmount;
  final String startDate;
  final String endDateCalculated;
  final bool isExpired;

  const GroupDetail({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.totalAmount,
    required this.startDate,
    required this.endDateCalculated,
    required this.isExpired,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      monthlyAmount: double.tryParse(json['monthly_amount'].toString()) ?? 0.0,
      durationMonths: int.tryParse(json['duration_months'].toString()) ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      startDate: json['start_date'] as String? ?? '',
      endDateCalculated: json['end_date_calculated'] as String? ?? '',
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    monthlyAmount,
    durationMonths,
    totalAmount,
    startDate,
    endDateCalculated,
    isExpired,
  ];
}

class GroupMember extends Equatable {
  final int id;
  final String name;
  final String phone;
  final int tokenNo;
  final String status;

  const GroupMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.tokenNo,
    required this.status,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      tokenNo: int.tryParse(json['token_no'].toString()) ?? 0,
      status: json['status'] as String? ?? 'Active',
    );
  }

  @override
  List<Object?> get props => [id, name, phone, tokenNo, status];
}

class GroupAuction extends Equatable {
  final int id;
  final int group;
  final int monthNo;
  final String auctionDate;
  final int winner;
  final int winnerToken;
  final String winnerName;
  final String status;
  final String action;

  const GroupAuction({
    required this.id,
    required this.group,
    required this.monthNo,
    required this.auctionDate,
    required this.winner,
    required this.winnerToken,
    required this.winnerName,
    required this.status,
    required this.action,
  });

  factory GroupAuction.fromJson(Map<String, dynamic> json) {
    return GroupAuction(
      id: int.tryParse(json['id'].toString()) ?? 0,
      group: int.tryParse(json['group'].toString()) ?? 0,
      monthNo: int.tryParse(json['month_no'].toString()) ?? 0,
      auctionDate: json['auction_date'] as String? ?? '',
      winner: int.tryParse(json['winner'].toString()) ?? 0,
      winnerToken: int.tryParse(json['winner_token'].toString()) ?? 0,
      winnerName: json['winner_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }

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

class GroupDetailsResponse extends Equatable {
  final GroupDetail group;
  final List<GroupMember> members;
  final List<GroupAuction> auctions;

  const GroupDetailsResponse({
    required this.group,
    required this.members,
    required this.auctions,
  });

  factory GroupDetailsResponse.fromJson(Map<String, dynamic> json) {
    return GroupDetailsResponse(
      group: GroupDetail.fromJson(json['group'] as Map<String, dynamic>),
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      auctions:
          (json['auctions'] as List<dynamic>?)
              ?.map((e) => GroupAuction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [group, members, auctions];
}
