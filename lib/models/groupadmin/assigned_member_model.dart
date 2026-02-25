class AssignedMemberResponse {
  final int totalMembers;
  final int totalPages;
  final int currentPage;
  final String? next;
  final String? previous;
  final List<AssignedMember> results;

  AssignedMemberResponse({
    required this.totalMembers,
    required this.totalPages,
    required this.currentPage,
    this.next,
    this.previous,
    required this.results,
  });

  factory AssignedMemberResponse.fromJson(Map<String, dynamic> json) {
    return AssignedMemberResponse(
      totalMembers: json['total_members'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      currentPage: json['current_page'] as int? ?? 1,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => AssignedMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_members': totalMembers,
      'total_pages': totalPages,
      'current_page': currentPage,
      'next': next,
      'previous': previous,
      'results': results.map((e) => e.toJson()).toList(),
    };
  }
}

class AssignedMember {
  final int id;
  final String name;
  final String phone;
  final String groupName;
  final String collectorName;
  final double monthlyAmount;

  AssignedMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.groupName,
    required this.collectorName,
    required this.monthlyAmount,
  });

  factory AssignedMember.fromJson(Map<String, dynamic> json) {
    return AssignedMember(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      collectorName: json['collector_name'] as String? ?? '',
      monthlyAmount: (json['monthly_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'group_name': groupName,
      'collector_name': collectorName,
      'monthly_amount': monthlyAmount,
    };
  }
}
