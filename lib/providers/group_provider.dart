import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/groupadmin/dashboard_model.dart';
import '../models/groupadmin/group_model.dart';
import '../models/groupadmin/profile_model.dart';
import '../models/groupadmin/member_list.dart';
import '../models/groupadmin/collection_list_model.dart';
import '../models/groupadmin/cashcollector/cashcollector_list.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// Shared providers
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiService(storageService: storageService);
});

// Dashboard provider
final dashboardDataProvider = FutureProvider<DashboardResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDashboardData();
});

// Group provider
final groupListProvider = FutureProvider<GroupListResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getGroups();
});

// Profile provider
final profileProvider = FutureProvider<ProfileResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getProfile();
});

// Member list provider
final memberListProvider = FutureProvider<MemberListResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMembers();
});

// Collection list provider
final collectionListProvider = FutureProvider<CollectionListResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCollections();
});

// Collector list provider
final collectorListProvider = FutureProvider<CashCollectorListResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCollectors();
});
