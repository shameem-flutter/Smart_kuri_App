import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/groupadmin/group_model.dart';
import '../models/groupadmin/auction/auction_group_details_model.dart';
import '../models/groupadmin/auction/auction_details_model.dart';
import '../models/groupadmin/auction/spin_auction_model.dart';
import 'group_provider.dart';

// Auctions provider
final auctionListProvider = FutureProvider<GroupListResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAuctions();
});

// Auction Group Details provider
final auctionGroupDetailsProvider = FutureProvider.family<AuctionGroupDetailsResponse, String>((ref, groupId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAuctionGroupDetails(groupId);
});

// Single Auction Details provider
final auctionDetailsProvider = FutureProvider.family<AuctionDetailsResponse, int>((ref, auctionId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAuctionDetails(auctionId);
});

// Spin Auction provider
final spinAuctionProvider = FutureProvider.family<SpinAuctionResponse, int>((ref, auctionId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSpinAuctionData(auctionId);
});
