import 'package:equatable/equatable.dart';

class PlanModel extends Equatable {
  final int id;
  final String name;
  final String price;
  final int durationDays;
  final int maxMembers;
  final int maxGroups;
  final bool isActive;

  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.maxMembers,
    required this.maxGroups,
    required this.isActive,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as String,
      durationDays: json['duration_days'] as int,
      maxMembers: json['max_members'] as int,
      maxGroups: json['max_groups'] as int,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration_days': durationDays,
      'max_members': maxMembers,
      'max_groups': maxGroups,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        durationDays,
        maxMembers,
        maxGroups,
        isActive,
      ];
}

class PlanListResponse extends Equatable {
  final bool success;
  final List<PlanModel> plans;

  const PlanListResponse({
    required this.success,
    required this.plans,
  });

  factory PlanListResponse.fromJson(Map<String, dynamic> json) {
    return PlanListResponse(
      success: json['success'] as bool? ?? false,
      plans: (json['plans'] as List<dynamic>?)
              ?.map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [success, plans];
}
