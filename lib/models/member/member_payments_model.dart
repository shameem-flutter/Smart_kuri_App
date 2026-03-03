import 'package:equatable/equatable.dart';

class MemberPaymentsResponse extends Equatable {
  final double totalPaid;
  final List<MemberPayment> payments;

  const MemberPaymentsResponse({
    required this.totalPaid,
    required this.payments,
  });

  factory MemberPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return MemberPaymentsResponse(
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => MemberPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [totalPaid, payments];
}

class MemberPayment extends Equatable {
  final int id;
  final int group;
  final String groupName;
  final int member;
  final String memberName;
  final double amount;
  final String paidDate;
  final String paymentMethod;
  final String paymentStatus;
  final String collectedByName;

  const MemberPayment({
    required this.id,
    required this.group,
    required this.groupName,
    required this.member,
    required this.memberName,
    required this.amount,
    required this.paidDate,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.collectedByName,
  });

  factory MemberPayment.fromJson(Map<String, dynamic> json) {
    return MemberPayment(
      id: json['id'] ?? 0,
      group: json['group'] ?? 0,
      groupName: json['group_name'] ?? '',
      member: json['member'] ?? 0,
      memberName: json['member_name'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidDate: json['paid_date'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      collectedByName: json['collected_by_name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        group,
        groupName,
        member,
        memberName,
        amount,
        paidDate,
        paymentMethod,
        paymentStatus,
        collectedByName,
      ];
}
