import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/collector/today_collections_model.dart';

class TodayCollectionsScreen extends ConsumerStatefulWidget {
  const TodayCollectionsScreen({super.key});

  @override
  ConsumerState<TodayCollectionsScreen> createState() =>
      _TodayCollectionsScreenState();
}

class _TodayCollectionsScreenState
    extends ConsumerState<TodayCollectionsScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds so the screen stays up to date
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(todayCollectionsProvider);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // We handle deletion directly inside the Dismissible's confirmDismiss callback now
  Future<bool> _handleDismiss(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Remove this collection record?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    // Show a loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 16),
              Text('Deleting...', style: GoogleFonts.inter()),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deletePayment(id);
      if (mounted) {
        ref.invalidate(todayCollectionsProvider);
        return true; // Successfully deleted, animate the item away
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      return false; // Deletion failed, snap the item back
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayCollectionsAsyncValue = ref.watch(todayCollectionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: todayCollectionsAsyncValue.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayCollectionsProvider);
            // Wait for the provider to complete refetching
            await ref.read(todayCollectionsProvider.future);
          },
          color: primaryColor,
          child: _buildCustomScroll(data),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(),
      ),
    );
  }

  Widget _buildCustomScroll(TodayCollectionsResponse data) {
    return CustomScrollView(
      slivers: [
        // Collapsible Premium Header
        SliverAppBar(
          expandedHeight: 220.0,
          floating: false,
          pinned: true,
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () =>
                ref.read(collectorScreenIndexProvider.notifier).goTo(0),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: Text(
              'Today\'s Collections',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${data.totalCollected.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Edge-to-Edge Ledger List
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'TRANSACTIONS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        data.payments.isEmpty
            ? SliverFillRemaining(child: _buildEmptyState())
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final payment = data.payments[index];
                  return _buildDismissibleListItem(payment);
                }, childCount: data.payments.length),
              ),
      ],
    );
  }

  Widget _buildDismissibleListItem(TodayPayment payment) {
    return Dismissible(
      key: ValueKey(payment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _handleDismiss(payment.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red[400],
        child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12), // Squircle shape
              ),
              child: Icon(
                payment.paymentMethod.toLowerCase().contains('cash')
                    ? Icons.money
                    : Icons.account_balance_wallet,
                color: primaryColor,
                size: 22,
              ),
            ),
            title: Text(
              payment.member,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              '${payment.paymentMethod} • ${payment.paidDate}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${payment.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(), // Removes default extra padding
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[300],
                    size: 22,
                  ),
                  onPressed: () => _handleDismiss(
                    payment.id,
                  ), // Reuses the same delete logic
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[100],
            indent: 80,
            endIndent: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text('Error loading data', style: GoogleFonts.poppins(fontSize: 16)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.invalidate(todayCollectionsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
