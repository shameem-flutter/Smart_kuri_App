import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/groupadmin/dashboard_model.dart';
import '../models/groupadmin/group_model.dart';
import '../models/groupadmin/profile_model.dart';
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
