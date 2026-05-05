import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final String createdAt;
  final double? amount;
  final int? count;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.amount,
    this.count,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      count: json['count'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, title, message, createdAt, amount, count];
}

class NotificationListResponse extends Equatable {
  final List<NotificationModel> notifications;

  const NotificationListResponse({required this.notifications});

  factory NotificationListResponse.fromJson(dynamic json) {
    if (json is List) {
      return NotificationListResponse(
        notifications: json
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else if (json is Map<String, dynamic> && json.containsKey('notifications')) {
      return NotificationListResponse(
        notifications: (json['notifications'] as List<dynamic>)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else if (json is Map<String, dynamic> && json.containsKey('total_pending_count')) {
      final int totalCount = json['total_pending_count'] as int? ?? 0;
      if (totalCount > 0) {
        final List<dynamic> pendingGroups = json['pending_groups'] as List<dynamic>? ?? [];
        final String groupNames = pendingGroups.map((g) => g['group__name']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
        
        double totalAmount = 0.0;
        for (var group in pendingGroups) {
          totalAmount += double.tryParse(group['total_pending'].toString()) ?? 0.0;
        }

        return NotificationListResponse(
          notifications: [
            NotificationModel(
              id: 0,
              title: '$totalCount Cash Handover${totalCount > 1 ? 's' : ''}',
              message: groupNames.isNotEmpty ? 'Pending payments in: $groupNames' : 'You have pending payments to approve.',
              createdAt: DateTime.now().toIso8601String(),
              amount: totalAmount,
              count: totalCount,
            )
          ],
        );
      }
      return const NotificationListResponse(notifications: []);
    } else if (json is Map<String, dynamic>) {
       return const NotificationListResponse(notifications: []);
    }
    return const NotificationListResponse(notifications: []);
  }

  @override
  List<Object?> get props => [notifications];
}
