import 'package:equatable/equatable.dart';

class GroupCreateRequest extends Equatable {
  final String name;
  final double monthlyAmount;
  final int durationMonths;
  final String startDate;

  const GroupCreateRequest({
    required this.name,
    required this.monthlyAmount,
    required this.durationMonths,
    required this.startDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'monthly_amount': monthlyAmount,
      'duration_months': durationMonths,
      'start_date': startDate,
    };
  }

  @override
  List<Object?> get props => [name, monthlyAmount, durationMonths, startDate];
}

class GroupCreateResponse extends Equatable {
  final String message;
  final Map<String, dynamic> group;

  const GroupCreateResponse({required this.message, required this.group});

  int get id => group['id'] as int? ?? 0;

  factory GroupCreateResponse.fromJson(Map<String, dynamic> json) {
    return GroupCreateResponse(
      message: json['message'] as String? ?? '',
      group: json['group'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [message, group];
}
