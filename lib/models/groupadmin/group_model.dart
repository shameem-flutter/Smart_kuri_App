import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final int id;
  final String name;
  final double monthlyAmount;
  final int durationMonths;
  final double totalAmount;
  final String startDate;
  final int? parentGroup;

  const Group({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.totalAmount,
    required this.startDate,
    this.parentGroup,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String,
      monthlyAmount: double.tryParse(json['monthly_amount'].toString()) ?? 0.0,
      durationMonths: int.tryParse(json['duration_months'].toString()) ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      startDate: json['start_date'] as String? ?? '',
      parentGroup: json['parent_group'] != null
          ? int.tryParse(json['parent_group'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        monthlyAmount,
        durationMonths,
        totalAmount,
        startDate,
        parentGroup,
      ];
}

class GroupListResponse extends Equatable {
  final int count;
  final List<Group> groups;

  const GroupListResponse({
    required this.count,
    required this.groups,
  });

  factory GroupListResponse.fromJson(Map<String, dynamic> json) {
    return GroupListResponse(
      count: json['count'] as int? ?? 0,
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => Group.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [count, groups];
}
