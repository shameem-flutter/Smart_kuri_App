class MemberHistoryResponse {
  final MemberInfo member;
  final PaymentSummary summary;
  final List<PaymentHistoryItem> payments;

  MemberHistoryResponse({
    required this.member,
    required this.summary,
    required this.payments,
  });

  factory MemberHistoryResponse.fromJson(Map<String, dynamic> json) {
    return MemberHistoryResponse(
      member: MemberInfo.fromJson(json['member'] as Map<String, dynamic>),
      summary: PaymentSummary.fromJson(json['summary'] as Map<String, dynamic>),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MemberInfo {
  final int id;
  final String name;
  final String phone;

  MemberInfo({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class PaymentSummary {
  final int totalMonths;
  final double monthlyAmount;
  final double totalKuriAmount;
  final double totalPaid;
  final double pendingAmount;

  PaymentSummary({
    required this.totalMonths,
    required this.monthlyAmount,
    required this.totalKuriAmount,
    required this.totalPaid,
    required this.pendingAmount,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalMonths: json['total_months'] as int? ?? 0,
      monthlyAmount: (json['monthly_amount'] as num?)?.toDouble() ?? 0.0,
      totalKuriAmount: (json['total_kuri_amount'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentHistoryItem {
  final int id;
  final String paidDate;
  final double amount;
  final String paymentMethod;
  final String collectedBy;

  PaymentHistoryItem({
    required this.id,
    required this.paidDate,
    required this.amount,
    required this.paymentMethod,
    required this.collectedBy,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] as int? ?? 0,
      paidDate: json['paid_date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      collectedBy: json['collected_by'] as String? ?? '',
    );
  }
}
