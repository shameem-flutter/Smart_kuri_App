import 'package:equatable/equatable.dart';

class MemberDetailsResponse extends Equatable {
  final MemberDetailInfo member;
  final double totalCollected;
  final double totalDue;
  final int monthsPaid;
  final int durationMonths;
  final double monthlyAmount;
  final List<MonthWisePayment> monthWise;

  const MemberDetailsResponse({
    required this.member,
    required this.totalCollected,
    required this.totalDue,
    required this.monthsPaid,
    required this.durationMonths,
    required this.monthlyAmount,
    required this.monthWise,
  });

  factory MemberDetailsResponse.fromJson(Map<String, dynamic> json) {
    final memberDetails = json['member_details'] as Map<String, dynamic>? ?? {};
    final financialSummary = json['financial_summary'] as Map<String, dynamic>? ?? {};

    return MemberDetailsResponse(
      member: MemberDetailInfo.fromJson(memberDetails),
      totalCollected: (financialSummary['total_collected'] as num?)?.toDouble() ?? 0.0,
      totalDue: (financialSummary['pending_amount'] as num?)?.toDouble() ?? 0.0,
      monthsPaid: financialSummary['months_paid'] as int? ?? 0,
      durationMonths: financialSummary['duration_months'] as int? ?? 0,
      monthlyAmount: (memberDetails['monthly_amount'] as num?)?.toDouble() ?? 0.0,
      monthWise: (json['month_wise_payments'] as List<dynamic>?)
              ?.map((e) => MonthWisePayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        member,
        totalCollected,
        totalDue,
        monthsPaid,
        durationMonths,
        monthlyAmount,
        monthWise,
      ];
}

class MemberDetailInfo extends Equatable {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String aadhaarNo;
  final String status;
  final int tokenNo;
  final String group;

  const MemberDetailInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.aadhaarNo,
    required this.status,
    required this.tokenNo,
    required this.group,
  });

  factory MemberDetailInfo.fromJson(Map<String, dynamic> json) {
    return MemberDetailInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      aadhaarNo: json['aadhaar_no'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      tokenNo: json['token_no'] as int? ?? 0,
      group: json['chitti_group'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        address,
        aadhaarNo,
        status,
        tokenNo,
        group,
      ];
}

class MonthWisePayment extends Equatable {
  final int month;
  final double? amount;
  final String? paidDate;
  final String? collector;
  final String status;

  const MonthWisePayment({
    required this.month,
    this.amount,
    this.paidDate,
    this.collector,
    required this.status,
  });

  factory MonthWisePayment.fromJson(Map<String, dynamic> json) {
    return MonthWisePayment(
      month: json['month'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble(),
      paidDate: json['paid_date'] as String?,
      collector: json['collector'] as String?,
      status: json['status'] as String? ?? 'Pending',
    );
  }

  @override
  List<Object?> get props => [month, amount, paidDate, collector, status];
}
