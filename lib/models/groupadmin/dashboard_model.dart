import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalGroups;
  final int activeGroups;
  final int totalMembers;
  final double thisMonthCollection;
  final double totalReceived;

  const DashboardStats({
    required this.totalGroups,
    required this.activeGroups,
    required this.totalMembers,
    required this.thisMonthCollection,
    required this.totalReceived,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalGroups: int.tryParse(json['total_groups'].toString()) ?? 0,
      activeGroups: int.tryParse(json['active_groups'].toString()) ?? 0,
      totalMembers: int.tryParse(json['total_members'].toString()) ?? 0,
      thisMonthCollection: double.tryParse(json['this_month_collection'].toString()) ?? 0.0,
      totalReceived: double.tryParse(json['total_received'].toString()) ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        totalGroups,
        activeGroups,
        totalMembers,
        thisMonthCollection,
        totalReceived,
      ];
}

class DashboardGroup extends Equatable {
  final int id;
  final String name;
  final String code;
  final bool isActive;
  final int totalMembers;
  final double monthlyAmount;
  final int durationMonths;

  const DashboardGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    required this.totalMembers,
    required this.monthlyAmount,
    required this.durationMonths,
  });

  factory DashboardGroup.fromJson(Map<String, dynamic> json) {
    return DashboardGroup(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      code: json['code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      totalMembers: int.tryParse(json['total_members'].toString()) ?? 0,
      monthlyAmount: double.tryParse(json['monthly_amount'].toString()) ?? 0.0,
      durationMonths: int.tryParse(json['duration_months'].toString()) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        isActive,
        totalMembers,
        monthlyAmount,
        durationMonths,
      ];
}

class DashboardResponse extends Equatable {
  final DashboardStats stats;
  final List<DashboardGroup> groups;

  const DashboardResponse({
    required this.stats,
    required this.groups,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => DashboardGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [stats, groups];
}
