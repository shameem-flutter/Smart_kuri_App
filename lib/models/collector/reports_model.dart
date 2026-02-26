class ReportsResponse {
  final double dailyTotal;
  final double monthlyTotal;
  final List<ReportMember> paidMembers;
  final String? fromDate;
  final String? toDate;

  ReportsResponse({
    required this.dailyTotal,
    required this.monthlyTotal,
    required this.paidMembers,
    this.fromDate,
    this.toDate,
  });

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    return ReportsResponse(
      dailyTotal: (json['daily_total'] as num?)?.toDouble() ?? 0.0,
      monthlyTotal: (json['monthly_total'] as num?)?.toDouble() ?? 0.0,
      paidMembers:
          (json['paid_members'] as List<dynamic>?)
              ?.map((e) => ReportMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fromDate: json['from_date'] as String?,
      toDate: json['to_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_total': dailyTotal,
      'monthly_total': monthlyTotal,
      'paid_members': paidMembers.map((e) => e.toJson()).toList(),
      'from_date': fromDate,
      'to_date': toDate,
    };
  }
}

class ReportMember {
  final int id;
  final String memberName;
  final String group;
  final double amount;
  final String paymentMethod;
  final String paidDate;

  ReportMember({
    required this.id,
    required this.memberName,
    required this.group,
    required this.amount,
    required this.paymentMethod,
    required this.paidDate,
  });

  factory ReportMember.fromJson(Map<String, dynamic> json) {
    return ReportMember(
      id: json['id'] as int? ?? 0,
      memberName: json['member_name'] as String? ?? '',
      group: json['group'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      paidDate: json['paid_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_name': memberName,
      'group': group,
      'amount': amount,
      'payment_method': paymentMethod,
      'paid_date': paidDate,
    };
  }
}
