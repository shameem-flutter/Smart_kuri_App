class PendingMembersResponse {
  final String statusFilter;
  final List<PendingMember> members;

  PendingMembersResponse({
    required this.statusFilter,
    required this.members,
  });

  factory PendingMembersResponse.fromJson(Map<String, dynamic> json) {
    return PendingMembersResponse(
      statusFilter: json['status_filter'] as String? ?? 'pending',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => PendingMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_filter': statusFilter,
      'members': members.map((e) => e.toJson()).toList(),
    };
  }
}

class PendingMember {
  final String memberName;
  final int memberId;
  final String group;
  final String month;
  final double paid;
  final double due;
  final String status;

  PendingMember({
    required this.memberName,
    required this.memberId,
    required this.group,
    required this.month,
    required this.paid,
    required this.due,
    required this.status,
  });

  factory PendingMember.fromJson(Map<String, dynamic> json) {
    return PendingMember(
      memberName: json['member_name'] as String? ?? '',
      memberId: json['member_id'] as int? ?? 0,
      group: json['group'] as String? ?? '',
      month: json['month'] as String? ?? '',
      paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
      due: (json['due'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_name': memberName,
      'member_id': memberId,
      'group': group,
      'month': month,
      'paid': paid,
      'due': due,
      'status': status,
    };
  }
}
