class HandoverPendingModel {
  final double totalCollected;
  final double totalSent;
  final double handoverPending;
  final bool showCard;

  HandoverPendingModel({
    required this.totalCollected,
    required this.totalSent,
    required this.handoverPending,
    required this.showCard,
  });

  factory HandoverPendingModel.fromJson(Map<String, dynamic> json) {
    return HandoverPendingModel(
      totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0.0,
      totalSent: (json['total_sent'] as num?)?.toDouble() ?? 0.0,
      handoverPending: (json['handover_pending'] as num?)?.toDouble() ?? 0.0,
      showCard: json['show_card'] as bool? ?? false,
    );
  }
}
