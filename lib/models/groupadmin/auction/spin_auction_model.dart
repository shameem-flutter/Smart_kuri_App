class SpinAuctionResponse {
  final int auctionId;
  final String group;
  final List<EligibleMember> eligibleMembers;

  SpinAuctionResponse({
    required this.auctionId,
    required this.group,
    required this.eligibleMembers,
  });

  factory SpinAuctionResponse.fromJson(Map<String, dynamic> json) {
    return SpinAuctionResponse(
      auctionId: json['auction_id'] as int,
      group: json['group'] as String? ?? '',
      eligibleMembers: (json['eligible_members'] as List<dynamic>?)
              ?.map((e) => EligibleMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EligibleMember {
  final int id;
  final String name;

  EligibleMember({required this.id, required this.name});

  factory EligibleMember.fromJson(Map<String, dynamic> json) {
    return EligibleMember(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}
