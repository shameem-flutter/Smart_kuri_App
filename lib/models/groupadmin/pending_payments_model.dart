import 'package:equatable/equatable.dart';

class PaymentDetail extends Equatable {
  final int id;
  final String member;
  final double amount;
  final String date;
  final String collectedBy;

  const PaymentDetail({
    required this.id,
    required this.member,
    required this.amount,
    required this.date,
    required this.collectedBy,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      member: json['member'] as String? ?? 'Unknown',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      date: json['date'] as String? ?? '',
      collectedBy: json['collected_by'] as String? ?? 'eespp', // Defaulting to eespp as per image
    );
  }

  @override
  List<Object?> get props => [id, member, amount, date, collectedBy];
}

class GroupPendingPayments extends Equatable {
  final int groupId;
  final String groupName;
  final double totalPending;
  final double totalApproved;
  final int countPending;
  final int countApproved;
  final List<PaymentDetail> pendingPayments;
  final List<PaymentDetail> approvedPayments;

  const GroupPendingPayments({
    required this.groupId,
    required this.groupName,
    required this.totalPending,
    required this.totalApproved,
    required this.countPending,
    required this.countApproved,
    required this.pendingPayments,
    required this.approvedPayments,
  });

  factory GroupPendingPayments.fromJson(Map<String, dynamic> json) {
    return GroupPendingPayments(
      groupId: int.tryParse(json['group_id'].toString()) ?? 0,
      groupName: json['group_name'] as String? ?? 'Unknown',
      totalPending: double.tryParse(json['total_pending'].toString()) ?? 0.0,
      totalApproved: double.tryParse(json['total_approved'].toString()) ?? 0.0,
      countPending: int.tryParse(json['count_pending'].toString()) ?? 0,
      countApproved: int.tryParse(json['count_approved'].toString()) ?? 0,
      pendingPayments: (json['pending_payments'] as List<dynamic>?)
              ?.map((e) => PaymentDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      approvedPayments: (json['approved_payments'] as List<dynamic>?)
              ?.map((e) => PaymentDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        totalPending,
        totalApproved,
        countPending,
        countApproved,
        pendingPayments,
        approvedPayments,
      ];
}

class PendingPaymentsResponse extends Equatable {
  final List<GroupPendingPayments> groups;

  const PendingPaymentsResponse({required this.groups});

  factory PendingPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return PendingPaymentsResponse(
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => GroupPendingPayments.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [groups];
}
