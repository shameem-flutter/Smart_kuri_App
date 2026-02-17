import 'package:equatable/equatable.dart';


class ProfileData extends Equatable {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;

  const ProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, email, phone, role];
}

class SubscriptionInfo extends Equatable {
  final String plan;
  final bool isActive;
  final int maxGroups;
  final int remainingGroups;
  final int maxMembers;
  final int remainingMembers;

  const SubscriptionInfo({
    required this.plan,
    required this.isActive,
    required this.maxGroups,
    required this.remainingGroups,
    required this.maxMembers,
    required this.remainingMembers,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      maxGroups: int.tryParse(json['max_groups'].toString()) ?? 0,
      remainingGroups: int.tryParse(json['remaining_groups'].toString()) ?? 0,
      maxMembers: int.tryParse(json['max_members'].toString()) ?? 0,
      remainingMembers: int.tryParse(json['remaining_members'].toString()) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    plan,
    isActive,
    maxGroups,
    remainingGroups,
    maxMembers,
    remainingMembers,
  ];
}

class SubscriptionStatus extends Equatable {
  final bool active;
  final int daysLeft;
  final int hoursLeft;

  const SubscriptionStatus({
    required this.active,
    required this.daysLeft,
    required this.hoursLeft,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      active: json['active'] as bool? ?? false,
      daysLeft: int.tryParse(json['days_left'].toString()) ?? 0,
      hoursLeft: int.tryParse(json['hours_left'].toString()) ?? 0,
    );
  }

  @override
  List<Object?> get props => [active, daysLeft, hoursLeft];
}

class ProfileResponse extends Equatable {
  final ProfileData profile;
  final int groupsCount;
  final int membersCount;
  final SubscriptionInfo effectiveSubscription;
  final SubscriptionStatus subscriptionStatus;
  final String timeLeft;

  const ProfileResponse({
    required this.profile,
    required this.groupsCount,
    required this.membersCount,
    required this.effectiveSubscription,
    required this.subscriptionStatus,
    required this.timeLeft,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      profile: ProfileData.fromJson(
        json['profile'] as Map<String, dynamic>? ?? {},
      ),
      groupsCount: int.tryParse(json['groups_count'].toString()) ?? 0,
      membersCount: int.tryParse(json['members_count'].toString()) ?? 0,
      effectiveSubscription: SubscriptionInfo.fromJson(
        json['effective_subscription'] as Map<String, dynamic>? ?? {},
      ),
      subscriptionStatus: SubscriptionStatus.fromJson(
        json['subscription_status'] as Map<String, dynamic>? ?? {},
      ),
      timeLeft: json['time_left'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    profile,
    groupsCount,
    membersCount,
    effectiveSubscription,
    subscriptionStatus,
    timeLeft,
  ];
}
