class CollectorDashboardModel {
  final double todayCollection;
  final double monthlyCollection;
  final double totalCollection;
  final int activeMembers;
  final List<RecentPayment> recentPayments;

  CollectorDashboardModel({
    required this.todayCollection,
    required this.monthlyCollection,
    required this.totalCollection,
    required this.activeMembers,
    required this.recentPayments,
  });

  factory CollectorDashboardModel.fromJson(Map<String, dynamic> json) {
    return CollectorDashboardModel(
      todayCollection: (json['today_collection'] as num?)?.toDouble() ?? 0.0,
      monthlyCollection: (json['monthly_collection'] as num?)?.toDouble() ?? 0.0,
      totalCollection: (json['total_collection'] as num?)?.toDouble() ?? 0.0,
      activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      recentPayments: (json['recent_payments'] as List<dynamic>?)
              ?.map((e) => RecentPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_collection': todayCollection,
      'monthly_collection': monthlyCollection,
      'total_collection': totalCollection,
      'active_members': activeMembers,
      'recent_payments': recentPayments.map((e) => e.toJson()).toList(),
    };
  }
}

class RecentPayment {
  final String member;
  final double amount;
  final String date;
  final String time;

  RecentPayment({
    required this.member,
    required this.amount,
    required this.date,
    required this.time,
  });

  factory RecentPayment.fromJson(Map<String, dynamic> json) {
    return RecentPayment(
      member: json['member'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member': member,
      'amount': amount,
      'date': date,
      'time': time,
    };
  }
}
