class AuctionDetailsResponse {
  final int id;
  final String group;
  final String? auctionDate;
  final bool isClosed;
  final AuctionWinner? winner;

  AuctionDetailsResponse({
    required this.id,
    required this.group,
    this.auctionDate,
    required this.isClosed,
    this.winner,
  });

  factory AuctionDetailsResponse.fromJson(Map<String, dynamic> json) {
    return AuctionDetailsResponse(
      id: json['id'] as int,
      group: json['group'] as String? ?? '',
      auctionDate: json['auction_date'] as String?,
      isClosed: json['is_closed'] as bool? ?? false,
      winner: json['winner'] != null
          ? AuctionWinner.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group': group,
      'auction_date': auctionDate,
      'is_closed': isClosed,
      'winner': winner?.toJson(),
    };
  }
}

class AuctionWinner {
  final int id;
  final String name;

  AuctionWinner({
    required this.id,
    required this.name,
  });

  factory AuctionWinner.fromJson(Map<String, dynamic> json) {
    return AuctionWinner(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
