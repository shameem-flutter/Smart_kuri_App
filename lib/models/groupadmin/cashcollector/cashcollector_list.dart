import 'package:equatable/equatable.dart';

class CashCollectorListItem extends Equatable {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String groupName;
  final bool status;

  const CashCollectorListItem({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.groupName,
    required this.status,
  });

  factory CashCollectorListItem.fromJson(Map<String, dynamic> json) {
    return CashCollectorListItem(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      status: json['status'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, username, email, phone, groupName, status];
}

class CashCollectorListResponse extends Equatable {
  final int count;
  final List<CashCollectorListItem> results;

  const CashCollectorListResponse({
    required this.count,
    required this.results,
  });

  factory CashCollectorListResponse.fromJson(Map<String, dynamic> json) {
    return CashCollectorListResponse(
      count: json['count'] as int? ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => CashCollectorListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [count, results];
}
