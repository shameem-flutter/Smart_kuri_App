import 'package:equatable/equatable.dart';

class CollectionCreateRequest extends Equatable {
  final int group;
  final int member;
  final double amount;
  final String paidDate;
  final String paymentMethod;
  final String paymentStatus;

  const CollectionCreateRequest({
    required this.group,
    required this.member,
    required this.amount,
    required this.paidDate,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'group': group,
      'member': member,
      'amount': amount,
      'paid_date': paidDate,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
    };
  }

  @override
  List<Object?> get props => [
    group,
    member,
    amount,
    paidDate,
    paymentMethod,
    paymentStatus,
  ];
}
