import 'package:equatable/equatable.dart';

class CollectionListResponse extends Equatable {
  final double totalCollected;
  final int count;
  final List<Payment> payments;

  const CollectionListResponse({
    required this.totalCollected,
    required this.count,
    required this.payments,
  });

  factory CollectionListResponse.fromJson(Map<String, dynamic> json) {
    final paymentsList = (json['payments'] as List<dynamic>? ?? json['results'] as List<dynamic>?)
            ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    double parsedTotal = double.tryParse(json['total_collected']?.toString() ?? '') ??
        double.tryParse(json['total_amount']?.toString() ?? '') ?? 0.0;

    if (parsedTotal == 0.0 && paymentsList.isNotEmpty) {
      parsedTotal = paymentsList.fold(
        0.0,
        (sum, p) => p.status.toLowerCase() == 'success' ? sum + p.amount : sum,
      );
    }

    return CollectionListResponse(
      totalCollected: parsedTotal,
      count: json['count'] as int? ?? paymentsList.length,
      payments: paymentsList,
    );
  }

  @override
  List<Object?> get props => [totalCollected, count, payments];
}

class Payment extends Equatable {
  final int id;
  final String member;
  final double amount;
  final String paidDate;
  final String status;
  final String paymentMethod;
  final String collectedBy;

  const Payment({
    required this.id,
    required this.member,
    required this.amount,
    required this.paidDate,
    required this.status,
    required this.paymentMethod,
    required this.collectedBy,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int? ?? 0,
      member: json['member'] as String? ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paidDate: json['paid_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      collectedBy: json['collected_by'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    member,
    amount,
    paidDate,
    status,
    paymentMethod,
    collectedBy,
  ];
}
