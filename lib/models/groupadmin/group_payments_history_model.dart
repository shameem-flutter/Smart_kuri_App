import 'package:equatable/equatable.dart';

class GroupPaymentItem extends Equatable {
  final int id;
  final String member;
  final double amount;
  final String paidDate;
  final String collector;
  final String status;

  const GroupPaymentItem({
    required this.id,
    required this.member,
    required this.amount,
    required this.paidDate,
    required this.collector,
    required this.status,
  });

  factory GroupPaymentItem.fromJson(Map<String, dynamic> json) {
    return GroupPaymentItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      member: json['member'] as String? ?? 'Unknown',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paidDate: json['paid_date'] as String? ?? '',
      collector: json['collector'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';

  @override
  List<Object?> get props => [id, member, amount, paidDate, collector, status];
}

class GroupPaymentsHistoryResponse extends Equatable {
  final int groupId;
  final String groupName;
  final List<GroupPaymentItem> payments;

  const GroupPaymentsHistoryResponse({
    required this.groupId,
    required this.groupName,
    required this.payments,
  });

  factory GroupPaymentsHistoryResponse.fromJson(Map<String, dynamic> json) {
    return GroupPaymentsHistoryResponse(
      groupId: int.tryParse(json['group_id'].toString()) ?? 0,
      groupName: json['group_name'] as String? ?? 'Unknown',
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => GroupPaymentItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  double get totalApproved => payments
      .where((p) => p.isApproved)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get totalPending => payments
      .where((p) => p.isPending)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get totalRejected => payments
      .where((p) => p.isRejected)
      .fold(0.0, (sum, p) => sum + p.amount);

  int get approvedCount => payments.where((p) => p.isApproved).length;
  int get pendingCount => payments.where((p) => p.isPending).length;
  int get rejectedCount => payments.where((p) => p.isRejected).length;

  @override
  List<Object?> get props => [groupId, groupName, payments];
}
