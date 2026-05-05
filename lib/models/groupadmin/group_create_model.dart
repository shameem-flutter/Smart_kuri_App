import 'package:equatable/equatable.dart';

class GroupCreateRequest extends Equatable {
  final int? planId;
  final String name;
  final int monthlyAmount; // Amount as integer (e.g. 3000)
  final int durationMonths;
  final String startDate; // DD-MM-YYYY
  final int auctionsPerMonth;
  final String auctionType; // "monthly" | "interval"
  final int? auctionIntervalMonths; // required only when auctionType == "interval"
  final String? auctionDate1; // yyyy-MM-dd
  final List<String> otherAuctionDates; // [auction_date_2, auction_date_3, ...]

  const GroupCreateRequest({
    this.planId,
    required this.name,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.startDate,
    required this.auctionsPerMonth,
    required this.auctionType,
    this.auctionIntervalMonths,
    this.auctionDate1,
    this.otherAuctionDates = const [],
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'monthly_amount': monthlyAmount,
      'duration_months': durationMonths,
      'start_date': startDate,
      'auctions_per_month': auctionsPerMonth,
      'auction_type': auctionType,
    };
    if (planId != null) {
      json['plan_id'] = planId;
    }
    if (auctionIntervalMonths != null) {
      json['auction_interval_months'] = auctionIntervalMonths;
    } else if (auctionType == 'monthly') {
      json['auction_interval_months'] = null; // Explicit null as per example
    }
    if (auctionDate1 != null && auctionDate1!.isNotEmpty) {
      json['auction_date_1'] = auctionDate1;
    }
    for (int i = 0; i < otherAuctionDates.length; i++) {
      final date = otherAuctionDates[i];
      if (date.isNotEmpty) {
        json['auction_date_${i + 2}'] = date;
      }
    }
    return json;
  }

  @override
  List<Object?> get props => [
        planId,
        name,
        monthlyAmount,
        durationMonths,
        startDate,
        auctionsPerMonth,
        auctionType,
        auctionIntervalMonths,
        auctionDate1,
        otherAuctionDates,
      ];
}

class GroupCreateResponse extends Equatable {
  final String message;
  final Map<String, dynamic> group;

  const GroupCreateResponse({required this.message, required this.group});

  int get id => group['id'] as int? ?? 0;

  factory GroupCreateResponse.fromJson(Map<String, dynamic> json) {
    return GroupCreateResponse(
      message: json['message'] as String? ?? '',
      group: json['group'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [message, group];
}
