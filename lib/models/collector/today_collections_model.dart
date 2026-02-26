class TodayCollectionsResponse {
  final double totalCollected;
  final List<TodayPayment> payments;

  TodayCollectionsResponse({
    required this.totalCollected,
    required this.payments,
  });

  factory TodayCollectionsResponse.fromJson(Map<String, dynamic> json) {
    return TodayCollectionsResponse(
      totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0.0,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => TodayPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_collected': totalCollected,
      'payments': payments.map((e) => e.toJson()).toList(),
    };
  }
}

class TodayPayment {
  final int id;
  final String member;
  final double amount;
  final String paymentMethod;
  final String paidDate;

  TodayPayment({
    required this.id,
    required this.member,
    required this.amount,
    required this.paymentMethod,
    required this.paidDate,
  });

  factory TodayPayment.fromJson(Map<String, dynamic> json) {
    return TodayPayment(
      id: json['id'] as int? ?? 0,
      member: json['member'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      paidDate: json['paid_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member,
      'amount': amount,
      'payment_method': paymentMethod,
      'paid_date': paidDate,
    };
  }
}
