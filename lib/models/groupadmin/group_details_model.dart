
import 'package:equatable/equatable.dart';

class GroupDetail extends Equatable {
  final int id;
  final String name;
  final double monthlyAmount;
  final int durationMonths;
  final double totalAmount;
  final String startDate;
  final String registrationStartDate;
  final String endDate;
  final bool isExpired;
  final int totalMembers;
  final double monthlyPot;
  final int currentMonth;
  final int completedMonths;
  final int remainingMonths;
  final double totalCollected;
  final double pendingTotal;
  final double collectionEfficiency;
  final String lastWinner;
  final double lastPrize;
  final double lastDiscount;

  const GroupDetail({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.totalAmount,
    required this.startDate,
    required this.registrationStartDate,
    required this.endDate,
    required this.isExpired,
    required this.totalMembers,
    required this.monthlyPot,
    required this.currentMonth,
    required this.completedMonths,
    required this.remainingMonths,
    required this.totalCollected,
    required this.pendingTotal,
    required this.collectionEfficiency,
    required this.lastWinner,
    required this.lastPrize,
    required this.lastDiscount,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      monthlyAmount: double.tryParse(json['monthly_amount'].toString()) ?? 0.0,
      durationMonths: int.tryParse(json['duration_months'].toString()) ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      startDate: json['start_date'] as String? ?? '',
      registrationStartDate: json['registration_start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      isExpired: json['is_expired'] as bool? ?? false,
      totalMembers: int.tryParse(json['total_members'].toString()) ?? 0,
      monthlyPot: double.tryParse(json['monthly_pot'].toString()) ?? 0.0,
      currentMonth: int.tryParse(json['current_month'].toString()) ?? 0,
      completedMonths: int.tryParse(json['completed_months'].toString()) ?? 0,
      remainingMonths: int.tryParse(json['remaining_months'].toString()) ?? 0,
      totalCollected: double.tryParse(json['total_collected'].toString()) ?? 0.0,
      pendingTotal: double.tryParse(json['pending_total'].toString()) ?? 0.0,
      collectionEfficiency:
          double.tryParse(json['collection_efficiency'].toString()) ?? 0.0,
      lastWinner: json['last_winner'] as String? ?? '',
      lastPrize: double.tryParse(json['last_prize'].toString()) ?? 0.0,
      lastDiscount: double.tryParse(json['last_discount'].toString()) ?? 0.0,
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
    registrationStartDate,
    endDate,
    isExpired,
    totalMembers,
    monthlyPot,
    currentMonth,
    completedMonths,
    remainingMonths,
    totalCollected,
    pendingTotal,
    collectionEfficiency,
    lastWinner,
    lastPrize,
    lastDiscount,
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
  final int monthNo;
  final int auctionNo;
  final String auctionDate;
  final String? winner;
  final double? bidAmount;
  final double prize;

  const GroupAuction({
    required this.id,
    required this.monthNo,
    required this.auctionNo,
    required this.auctionDate,
    this.winner,
    this.bidAmount,
    required this.prize,
  });

  factory GroupAuction.fromJson(Map<String, dynamic> json) {
    return GroupAuction(
      id: int.tryParse(json['id'].toString()) ?? 0,
      monthNo: int.tryParse(json['month_no'].toString()) ?? 0,
      auctionNo: int.tryParse(json['auction_no'].toString()) ?? 0,
      auctionDate: json['auction_date'] as String? ?? '',
      winner: json['winner'] as String?,
      bidAmount:
          json['bid_amount'] != null
              ? double.tryParse(json['bid_amount'].toString())
              : null,
      prize: double.tryParse(json['prize'].toString()) ?? 0.0,
    );
  }

  String get status => winner != null ? 'Completed' : 'Pending';

  @override
  List<Object?> get props => [
    id,
    monthNo,
    auctionNo,
    auctionDate,
    winner,
    bidAmount,
    prize,
  ];
}

class GroupDetailsResponse extends Equatable {
  final GroupDetail group;
  final List<GroupMember> members;
  final List<GroupAuction> auctions;
  final String today;

  const GroupDetailsResponse({
    required this.group,
    required this.members,
    required this.auctions,
    required this.today,
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
      today: json['today'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [group, members, auctions, today];
}
