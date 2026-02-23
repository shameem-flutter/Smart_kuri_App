class AuctionGroupDetailsResponse {
  final AuctionGroup group;
  final List<AuctionMonth> months;

  AuctionGroupDetailsResponse({
    required this.group,
    required this.months,
  });

  factory AuctionGroupDetailsResponse.fromJson(Map<String, dynamic> json) {
    return AuctionGroupDetailsResponse(
      group: AuctionGroup.fromJson(json['group'] as Map<String, dynamic>),
      months: (json['months'] as List<dynamic>)
          .map((e) => AuctionMonth.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group': group.toJson(),
      'months': months.map((e) => e.toJson()).toList(),
    };
  }
}

class AuctionGroup {
  final int id;
  final String name;
  final int durationMonths;
  final String? startDate;
  final String? endDate;

  AuctionGroup({
    required this.id,
    required this.name,
    required this.durationMonths,
    this.startDate,
    this.endDate,
  });

  factory AuctionGroup.fromJson(Map<String, dynamic> json) {
    return AuctionGroup(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      durationMonths: json['duration_months'] as int? ?? 0,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration_months': durationMonths,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}

class AuctionMonth {
  final int monthNo;
  final AuctionDetail? auction;

  AuctionMonth({
    required this.monthNo,
    this.auction,
  });

  factory AuctionMonth.fromJson(Map<String, dynamic> json) {
    return AuctionMonth(
      monthNo: json['month_no'] as int,
      auction: json['auction'] != null
          ? AuctionDetail.fromJson(json['auction'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month_no': monthNo,
      'auction': auction?.toJson(),
    };
  }
}

class AuctionDetail {
  final int id;
  final String? auctionDate;
  final bool isClosed;
  final String? winner;

  AuctionDetail({
    required this.id,
    this.auctionDate,
    required this.isClosed,
    this.winner,
  });

  factory AuctionDetail.fromJson(Map<String, dynamic> json) {
    return AuctionDetail(
      id: json['id'] as int,
      auctionDate: json['auction_date'] as String?,
      isClosed: json['is_closed'] as bool? ?? false,
      winner: json['winner'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_date': auctionDate,
      'is_closed': isClosed,
      'winner': winner,
    };
  }
}
