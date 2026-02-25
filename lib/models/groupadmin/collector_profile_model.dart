class CollectorProfileResponse {
  final CollectorProfile collector;
  final List<String> assignedGroups;

  CollectorProfileResponse({
    required this.collector,
    required this.assignedGroups,
  });

  factory CollectorProfileResponse.fromJson(Map<String, dynamic> json) {
    return CollectorProfileResponse(
      collector: CollectorProfile.fromJson(json['collector'] as Map<String, dynamic>),
      assignedGroups: (json['assigned_groups'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class CollectorProfile {
  final int id;
  final String username;
  final String phone;
  final String email;
  final String joined;

  CollectorProfile({
    required this.id,
    required this.username,
    required this.phone,
    required this.email,
    required this.joined,
  });

  factory CollectorProfile.fromJson(Map<String, dynamic> json) {
    return CollectorProfile(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      joined: json['joined'] as String? ?? '',
    );
  }
}
