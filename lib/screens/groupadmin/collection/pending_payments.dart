import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/groupadmin/pending_payments_model.dart';
import 'package:kuri_app/screens/groupadmin/collection/payment_history_screen.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/utilities/gap_func.dart';

// ─── Pending Payments Screen ──────────────────────────────────────────────────

class PendingPaymentsScreen extends ConsumerWidget {
  const PendingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: blackColor),
        title: pendingPaymentsAsync.when(
          data: (response) => Text(
            response.groups.length == 1
                ? response.groups.first.groupName
                : 'Pending Approvals',
            style: GoogleFonts.poppins(
              color: blackColor,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => Text(
            'Pending Approvals',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(pendingPaymentsProvider),
            icon: Icon(Icons.refresh_rounded, color: blackColor, size: 22),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: pendingPaymentsAsync.when(
          data: (response) => _buildContent(context, ref, response),
          loading: () =>
              Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (error, _) => _buildError(context, ref, error),
        ),
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: primaryColor.withValues(alpha: 0.5),
              ),
            ),
            vertGap(20),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            vertGap(8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.6,
              ),
            ),
            vertGap(28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.refresh(pendingPaymentsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ──────────────────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PendingPaymentsResponse response,
  ) {
    if (response.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 42,
                color: primaryColor.withValues(alpha: 0.4),
              ),
            ),
            vertGap(16),
            Text(
              'No groups found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            vertGap(6),
            Text(
              'Pending approvals will appear here.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFB0BEC5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async => ref.refresh(pendingPaymentsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        itemCount: response.groups.length,
        itemBuilder: (context, index) =>
            _GroupApprovalCard(group: response.groups[index]),
      ),
    );
  }
}

// ─── Group Approval Card ──────────────────────────────────────────────────────

class _GroupApprovalCard extends ConsumerStatefulWidget {
  final GroupPendingPayments group;

  const _GroupApprovalCard({required this.group});

  @override
  ConsumerState<_GroupApprovalCard> createState() => _GroupApprovalCardState();
}

class _GroupApprovalCardState extends ConsumerState<_GroupApprovalCard> {
  bool _approvingAll = false;
  bool _rejectingAll = false;

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveAll() async {
    if (_approvingAll || _rejectingAll) return;
    final group = widget.group;

    final confirmed = await _showConfirmDialog(
      title: 'Approve All?',
      message: 'Are you sure you want to approve all ${group.countPending} pending payments for ${group.groupName}?',
      confirmLabel: 'Approve All',
      confirmColor: const Color(0xFF10B981),
    );

    if (confirmed != true) return;

    setState(() => _approvingAll = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.approveGroupPayments(group.groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'All payments approved', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      ref.invalidate(pendingPaymentsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _approvingAll = false);
    }
  }

  Future<void> _handleRejectAll() async {
    if (_approvingAll || _rejectingAll) return;
    final group = widget.group;

    final confirmed = await _showConfirmDialog(
      title: 'Reject All?',
      message: 'Are you sure you want to reject all ${group.countPending} pending payments for ${group.groupName}?',
      confirmLabel: 'Reject All',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirmed != true) return;

    setState(() => _rejectingAll = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.rejectGroupPayments(group.groupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'All payments rejected', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      ref.invalidate(pendingPaymentsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _rejectingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final total = group.totalApproved + group.totalPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.groupName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      vertGap(2),
                      Text(
                        '₹${total.toInt()} total collection',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${group.countPending} pending',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Metrics Row ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        label: 'Approved',
                        value: '₹${group.totalApproved.toInt()}',
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFD1FAE5),
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    horiGap(12),
                    Expanded(
                      child: _MetricItem(
                        label: 'Pending',
                        value: '₹${group.totalPending.toInt()}',
                        iconColor: const Color(0xFFF59E0B),
                        iconBg: const Color(0xFFFEF3C7),
                        icon: Icons.timelapse_rounded,
                      ),
                    ),
                  ],
                ),
                vertGap(16),

                // ── Progress Bar ──────────────────────────────────────
                if (total > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: group.totalApproved / total,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                    ),
                  ),
                  vertGap(6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${((group.totalApproved / total) * 100).toStringAsFixed(0)}% approved',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${group.countApproved + group.countPending} total payments',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  vertGap(16),
                ],

                // ── History Button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupHistoryScreen(
                          groupId: group.groupId,
                          groupName: group.groupName,
                        ),
                      ),
                    ),
                    icon: Icon(
                      Icons.access_time_rounded,
                      size: 17,
                      color: primaryColor,
                    ),
                    label: Text(
                      'View History',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                vertGap(10),

                // ── Verify Individual Button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupPendingDetailScreen(groupId: group.groupId),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_ind_outlined, size: 17),
                    label: Text(
                      'Verify Individual (${group.countPending})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                vertGap(10),

                // ── Reject / Approve All ──────────────────────────────
                if (group.countPending > 0)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _rejectingAll ? null : _handleRejectAll,
                            icon: _rejectingAll
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                    color: Color(0xFFEF4444),
                                  ),
                            label: Text(
                              _rejectingAll ? 'Rejecting...' : 'Reject All',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              backgroundColor: const Color(0xFFFEF2F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _approvingAll ? null : _handleApproveAll,
                            icon: _approvingAll
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_rounded, size: 17),
                            label: Text(
                              _approvingAll ? 'Approving...' : 'Approve All',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                vertGap(16),

                // ── Sync Status Footer ────────────────────────────────
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 14,
                        color: primaryColor.withValues(alpha: 0.6),
                      ),
                      horiGap(6),
                      Text(
                        'Sync Ready · ${group.countPending} waiting',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Item ──────────────────────────────────────────────────────────────

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          horiGap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Group Pending Detail Screen ──────────────────────────────────────────────

class GroupPendingDetailScreen extends ConsumerWidget {
  final int groupId;

  const GroupPendingDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingPaymentsAsync = ref.watch(pendingPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: blackColor),
        title: Text(
          'Group Details',
          style: GoogleFonts.poppins(
            color: blackColor,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(pendingPaymentsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: pendingPaymentsAsync.when(
        data: (response) {
          final group = response.groups.firstWhere(
            (g) => g.groupId == groupId,
            orElse: () => throw Exception('Group not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary Cards ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStatCard(
                        label: 'Total Pending',
                        value: '₹${group.totalPending}',
                        subLabel:
                            '${group.countPending} payment${group.countPending == 1 ? '' : 's'}',
                        icon: Icons.timelapse_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        iconBg: const Color(0xFFFEF3C7),
                      ),
                    ),
                    horiGap(12),
                    Expanded(
                      child: _SummaryStatCard(
                        label: 'Total Approved',
                        value: '₹${group.totalApproved}',
                        subLabel:
                            '${group.countApproved} payment${group.countApproved == 1 ? '' : 's'}',
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFD1FAE5),
                      ),
                    ),
                  ],
                ),
                vertGap(28),

                // ── Section Header ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Payments',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Action Required',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                vertGap(14),

                // ── Payment Items ──────────────────────────────────────────
                if (group.pendingPayments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text(
                        'No pending payments',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  )
                else
                  ...group.pendingPayments.map(
                    (p) => PaymentItemWidget(payment: p, isPending: true),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}

// ─── Summary Stat Card ────────────────────────────────────────────────────────

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          vertGap(12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          vertGap(2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          vertGap(4),
          Text(
            subLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFB0BEC5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Item Widget ──────────────────────────────────────────────────────

class PaymentItemWidget extends ConsumerStatefulWidget {
  final PaymentDetail payment;
  final bool isPending;

  const PaymentItemWidget({
    super.key,
    required this.payment,
    required this.isPending,
  });

  @override
  ConsumerState<PaymentItemWidget> createState() => _PaymentItemWidgetState();
}

class _PaymentItemWidgetState extends ConsumerState<PaymentItemWidget> {
  bool _approving = false;
  bool _rejecting = false;

  Future<void> _handleApprove() async {
    if (_approving || _rejecting) return;

    final confirmed = await _showConfirmDialog(
      title: 'Approve Payment?',
      message:
          'Are you sure you want to approve this payment of ₹${widget.payment.amount}?',
      confirmLabel: 'Approve',
      confirmColor: const Color(0xFF10B981),
    );

    if (confirmed != true) return;

    setState(() => _approving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final msg = await api.approvePayment(widget.payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      ref.invalidate(pendingPaymentsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  Future<void> _handleReject() async {
    if (_approving || _rejecting) return;

    final confirmed = await _showConfirmDialog(
      title: 'Reject Payment?',
      message:
          'Are you sure you want to reject this payment of ₹${widget.payment.amount}?',
      confirmLabel: 'Reject',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirmed != true) return;

    setState(() => _rejecting = true);
    try {
      final api = ref.read(apiServiceProvider);
      final msg = await api.rejectPayment(widget.payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      ref.invalidate(pendingPaymentsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final isPending = widget.isPending;

    // ── Initials ──
    String initials = 'M';
    if (payment.member.isNotEmpty) {
      final parts = payment.member.trim().split(' ');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = payment.member
            .substring(0, payment.member.length.clamp(0, 2))
            .toUpperCase();
      }
    }

    final statusColor = isPending
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);
    final statusBg = isPending
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFD1FAE5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: primaryColor,
                fontSize: 15,
              ),
            ),
          ),
          horiGap(12),

          // ── Name, Amount & Date ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.member,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                vertGap(2),
                Text(
                  '₹${payment.amount}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                if (!isPending) ...[
                  vertGap(3),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      horiGap(4),
                      Text(
                        payment.date,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Actions or Status ──
          if (isPending)
            Column(
              children: [
                _PaymentActionButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEE2E2),
                  isLoading: _rejecting,
                  onTap: _handleReject,
                ),
                vertGap(8),
                _PaymentActionButton(
                  icon: Icons.check_rounded,
                  color: Colors.white,
                  bgColor: const Color(0xFF10B981),
                  isLoading: _approving,
                  onTap: _handleApprove,
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Approved',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _PaymentActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color, size: 18),
      ),
    );
  }
}
