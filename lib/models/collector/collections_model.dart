class CollectorCollectionsResponse {
  final List<CollectorGroup> groups;

  CollectorCollectionsResponse({required this.groups});

  factory CollectorCollectionsResponse.fromJson(Map<String, dynamic> json) {
    return CollectorCollectionsResponse(
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => CollectorGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groups': groups.map((e) => e.toJson()).toList(),
    };
  }
}

class CollectorGroup {
  final int groupId;
  final String groupName;
  final double totalCollector;
  final double totalAdmin;
  final double pending;
  final double notSent;
  final bool hasRejected;
  final List<CollectorPayment> payments;

  CollectorGroup({
    required this.groupId,
    required this.groupName,
    required this.totalCollector,
    required this.totalAdmin,
    required this.pending,
    required this.notSent,
    required this.hasRejected,
    required this.payments,
  });

  factory CollectorGroup.fromJson(Map<String, dynamic> json) {
    return CollectorGroup(
      groupId: (json['group_id'] as num?)?.toInt() ?? 0,
      groupName: json['group_name'] as String? ?? '',
      totalCollector: (json['total_collector'] as num?)?.toDouble() ?? 0.0,
      totalAdmin: (json['total_admin'] as num?)?.toDouble() ?? 0.0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0.0,
      notSent: (json['not_sent'] as num?)?.toDouble() ?? 0.0,
      hasRejected: json['has_rejected'] as bool? ?? false,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => CollectorPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'group_name': groupName,
      'total_collector': totalCollector,
      'total_admin': totalAdmin,
      'pending': pending,
      'not_sent': notSent,
      'has_rejected': hasRejected,
      'payments': payments.map((e) => e.toJson()).toList(),
    };
  }
}

class CollectorPayment {
  final int paymentId;
  final String memberName;
  final double amount;
  final String paidDate;
  final bool isToday;
  final bool sentToAdmin;
  final bool receivedByAdmin;
  final String adminStatus;

  CollectorPayment({
    required this.paymentId,
    required this.memberName,
    required this.amount,
    required this.paidDate,
    required this.isToday,
    required this.sentToAdmin,
    required this.receivedByAdmin,
    required this.adminStatus,
  });

  factory CollectorPayment.fromJson(Map<String, dynamic> json) {
    return CollectorPayment(
      paymentId: (json['payment_id'] as num?)?.toInt() ?? 0,
      memberName: json['member_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidDate: json['paid_date'] as String? ?? '',
      isToday: json['is_today'] as bool? ?? false,
      sentToAdmin: json['sent_to_admin'] as bool? ?? false,
      receivedByAdmin: json['received_by_admin'] as bool? ?? false,
      adminStatus: json['admin_status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'member_name': memberName,
      'amount': amount,
      'paid_date': paidDate,
      'is_today': isToday,
      'sent_to_admin': sentToAdmin,
      'received_by_admin': receivedByAdmin,
      'admin_status': adminStatus,
    };
  }
}
