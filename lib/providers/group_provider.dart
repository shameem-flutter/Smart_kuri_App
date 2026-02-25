import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/groupadmin/dashboard_model.dart';
import '../models/groupadmin/group_model.dart';
import '../models/groupadmin/profile_model.dart';
import '../models/groupadmin/member_list.dart';
import '../models/groupadmin/collection_list_model.dart';
import '../models/groupadmin/cashcollector/cashcollector_list.dart';
import '../models/groupadmin/collector_dashboard_model.dart';
import '../models/groupadmin/assigned_member_model.dart';
import '../models/groupadmin/member_history_model.dart';
import '../models/groupadmin/collector_profile_model.dart';
import '../models/collector/pending_member_model.dart';
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

// Collector Dashboard provider
final collectorDashboardProvider = FutureProvider<CollectorDashboardModel>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCollectorDashboardData();
});

// Pending Members provider
final pendingMembersProvider = FutureProvider<PendingMembersResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getPendingMembers();
});

// Assigned Members provider
final assignedMemberProvider = FutureProvider.family<AssignedMemberResponse, Map<String, int>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  final page = params['page'] ?? 1;
  final pageSize = params['pageSize'] ?? 100;
  return apiService.getAssignedMembers(page: page, pageSize: pageSize);
});

// Member History provider
final memberHistoryProvider = FutureProvider.family<MemberHistoryResponse, int>((ref, memberId) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemberHistory(memberId);
});

// Collector Profile provider
final collectorProfileProvider = FutureProvider<CollectorProfileResponse>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCollectorProfile();
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
