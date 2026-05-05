/// Model classes for member payment history.
///
/// Backend logic (Installment model):
///  - status        : 'pending' | 'partial' | 'paid'
///  - amount_due    : total amount owed for the installment
///  - amount_paid   : sum of payments already recorded
///  - pending_amount: amount_due − amount_paid  (computed by backend)
///  - total_paid    : aggregate of amount_paid across all installments
library;

class MemberHistoryResponse {
  final MemberInfo member;
  final PaymentSummary summary;
  final List<PaymentHistoryItem> payments;
  final List<MonthWiseHistoryItem> monthWise;

  MemberHistoryResponse({
    required this.member,
    required this.summary,
    required this.payments,
    required this.monthWise,
  });

  factory MemberHistoryResponse.fromJson(Map<String, dynamic> json) {
    final summary = PaymentSummary.fromJson(json['summary'] as Map<String, dynamic>);
    final payments = (json['payments'] as List<dynamic>?)
              ?.map(
                (e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];
    
    // Check if month_wise_payments is provided by API
    List<MonthWiseHistoryItem> monthWise;
    if (json.containsKey('month_wise_payments')) {
      monthWise = (json['month_wise_payments'] as List<dynamic>)
          .map((e) => MonthWiseHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Generate calculated month-wise status if not provided by backend
      monthWise = _calculateMonthWise(summary, payments);
    }

    return MemberHistoryResponse(
      member: MemberInfo.fromJson(json['member'] as Map<String, dynamic>),
      summary: summary,
      payments: payments,
      monthWise: monthWise,
    );
  }

  static List<MonthWiseHistoryItem> _calculateMonthWise(PaymentSummary summary, List<PaymentHistoryItem> payments) {
    List<MonthWiseHistoryItem> result = [];
    double totalPaidRemaining = summary.totalPaid;
    
    for (int i = 1; i <= summary.totalMonths; i++) {
      double target = summary.monthlyAmount;
      double received = 0;
      
      if (totalPaidRemaining >= target) {
        received = target;
        totalPaidRemaining -= target;
      } else if (totalPaidRemaining > 0) {
        received = totalPaidRemaining;
        totalPaidRemaining = 0;
      }
      
      double remaining = target - received;
      String status = remaining <= 0 ? 'Full Paid' : (received > 0 ? 'Partial' : 'Pending');
      
      result.add(MonthWiseHistoryItem(
        month: i,
        target: target,
        received: received,
        remaining: remaining,
        status: status,
        isAdvance: false, // We don't have enough info to determine advance here
      ));
    }
    return result;
  }
}

class MonthWiseHistoryItem {
  final int month;
  final double target;
  final double received;
  final double remaining;
  final String status;
  final bool isAdvance;

  MonthWiseHistoryItem({
    required this.month,
    required this.target,
    required this.received,
    required this.remaining,
    required this.status,
    required this.isAdvance,
  });

  factory MonthWiseHistoryItem.fromJson(Map<String, dynamic> json) {
    return MonthWiseHistoryItem(
      month: json['month'] as int? ?? 0,
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
      received: (json['paid'] as num?)?.toDouble() ?? (json['received'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['balance'] as num?)?.toDouble() ?? (json['remaining'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
      isAdvance: json['is_advance'] as bool? ?? false,
    );
  }
}

class MemberInfo {
  final int id;
  final String name;
  final String phone;

  MemberInfo({required this.id, required this.name, required this.phone});

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    return MemberInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class PaymentSummary {
  /// Installment status from the backend: 'pending' | 'partial' | 'paid'
  final String status;

  final int totalMonths;
  final double monthlyAmount;
  final double totalKuriAmount;

  /// Sum of amount_paid across all installments (Paid to Date)
  final double totalPaid;

  /// amount_due − amount_paid  (Required / Due)
  final double pendingAmount;

  PaymentSummary({
    required this.status,
    required this.totalMonths,
    required this.monthlyAmount,
    required this.totalKuriAmount,
    required this.totalPaid,
    required this.pendingAmount,
  });

  /// True when any installment is still pending or partially paid.
  bool get isDue => status == 'pending' || status == 'partial';

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      // Backend sends 'status' on the summary; fall back to checking
      // pending_amount if the field is absent for backwards compatibility.
      status: json['status'] as String? ?? _deriveStatus(json),
      totalMonths: json['total_months'] as int? ?? 0,
      monthlyAmount: (json['monthly_amount'] as num?)?.toDouble() ?? 0.0,
      totalKuriAmount: (json['total_kuri_amount'] as num?)?.toDouble() ?? 0.0,
      // "Paid to Date"  → amount_paid aggregated by backend as total_paid
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      // "Required / Due" → amount_due − amount_paid sent as pending_amount
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Derives a status string from numeric fields when the backend omits
  /// the explicit 'status' key (older API versions).
  static String _deriveStatus(Map<String, dynamic> json) {
    final pending = (json['pending_amount'] as num?)?.toDouble() ?? 0.0;
    final paid = (json['total_paid'] as num?)?.toDouble() ?? 0.0;
    if (pending <= 0) return 'paid';
    if (paid > 0) return 'partial';
    return 'pending';
  }
}

class PaymentHistoryItem {
  final int id;
  final String paidDate;
  final double amount;
  final String paymentMethod;
  final String collectedBy;

  PaymentHistoryItem({
    required this.id,
    required this.paidDate,
    required this.amount,
    required this.paymentMethod,
    required this.collectedBy,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] as int? ?? 0,
      paidDate: json['paid_date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? '',
      collectedBy: json['collected_by'] as String? ?? '',
    );
  }
}
