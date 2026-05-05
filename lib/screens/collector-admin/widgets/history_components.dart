import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kuri_app/models/collector/collections_model.dart';
import 'package:kuri_app/models/groupadmin/member_history_model.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
const _cardRadius = 20.0;
const _tileRadius = 14.0;
const _badgeRadius = 20.0;

const _textDark = Color(0xFF1C2B3A);
const _textMid = Color(0xFF6B7A8D);
const _surface = Colors.white;
const _surfaceDim = Color(0xFFF8F9FC);
const _border = Color(0xFFEAEDF2);

// Status palette
const _approvedBg = Color(0xFFE8FAF3);
const _approvedFg = Color(0xFF0E9F6E);
const _rejectedBg = Color(0xFFFEEAEA);
const _rejectedFg = Color(0xFFE53E3E);
const _pendingBg = Color(0xFFFFF8E6);
const _pendingFg = Color(0xFFD97706);

// ─────────────────────────────────────────────────────────────────────────────
// GroupHistoryCard
// ─────────────────────────────────────────────────────────────────────────────

class GroupHistoryCard extends StatelessWidget {
  final CollectorGroup group;
  const GroupHistoryCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(group: group),
          _GroupStats(group: group),
          SizedBox(height: 05),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "PAYMENTS:-",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                // const SizedBox(width: 10),
                _SendToAdminButton(group: group),
              ],
            ),
          ),

          _PaymentList(payments: group.payments),
        ],
      ),
    );
  }
}

// ─── Send to Admin Button ──────────────────────────────────────────────────

class _SendToAdminButton extends ConsumerStatefulWidget {
  final CollectorGroup group;
  const _SendToAdminButton({required this.group});

  @override
  ConsumerState<_SendToAdminButton> createState() => _SendToAdminButtonState();
}

class _SendToAdminButtonState extends ConsumerState<_SendToAdminButton> {
  bool _isLoading = false;

  Future<void> _handleSend() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.sendToAdmin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payments sent to admin successfully ✅'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      ref.invalidate(collectorCollectionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.group.notSent == 0) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleSend,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.send_rounded,
                  size: 12,
                  color: Color(0xFF3B82F6),
                ),
              const SizedBox(width: 4),
              Text(
                _isLoading ? 'Sending...' : 'Send to Admin',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Group Header ─────────────────────────────────────────────────────────────

class _GroupHeader extends ConsumerStatefulWidget {
  final CollectorGroup group;
  const _GroupHeader({required this.group});

  @override
  ConsumerState<_GroupHeader> createState() => _GroupHeaderState();
}

class _GroupHeaderState extends ConsumerState<_GroupHeader> {
  bool _isLoadingAll = false;
  bool _isLoadingResend = false;

  Future<void> _handleSendToAdmin(bool isResend) async {
    if (_isLoadingAll || _isLoadingResend) return;
    setState(() {
      if (isResend)
        _isLoadingResend = true;
      else
        _isLoadingAll = true;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      if (isResend) {
        await apiService.resendGroupPayments(widget.group.groupId);
      } else {
        await apiService.sendToAdmin();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payments sent to admin successfully ✅'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      ref.invalidate(collectorCollectionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAll = false;
          _isLoadingResend = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.92), primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Name + actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeaderChip(
                      label: 'Send All',
                      icon: Icons.send_rounded,
                      onTap: () => _handleSendToAdmin(false),
                      bgColor: Colors.white,
                      fgColor: primaryColor,
                      isLoading: _isLoadingAll,
                    ),
                    const SizedBox(width: 8),
                    if (group.hasRejected)
                      _HeaderChip(
                        label: 'Resend All Rejected',
                        icon: Icons.refresh_rounded,
                        onTap: () => _handleSendToAdmin(true),
                        bgColor: const Color(0xFFFBBF24),
                        fgColor: const Color(0xFF5A4100),
                        isLoading: _isLoadingResend,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color fgColor;
  final bool isLoading;

  const _HeaderChip({
    required this.label,
    required this.icon,
    this.onTap,
    required this.bgColor,
    required this.fgColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            else
              Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 5),
            Text(
              isLoading ? 'Sending...' : label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Group Stats ──────────────────────────────────────────────────────────────

class _GroupStats extends StatelessWidget {
  final CollectorGroup group;
  const _GroupStats({required this.group});

  @override
  Widget build(BuildContext context) {
    // Progress: sent / total
    final total = group.totalCollector;
    final sent = group.pending; // "pending" = already sent to admin
    final ratio = total > 0 ? (sent / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      color: _surfaceDim,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          // Top row stats
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total',
                  amount: group.totalCollector,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF6366F1),
                  iconBg: const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Admin Recieved',
                  amount: group.totalAdmin,
                  icon: Icons.check_circle_rounded,
                  iconColor: _approvedFg,
                  iconBg: _approvedBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Sent',
                  amount: group.pending,
                  icon: Icons.send_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  iconBg: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Draft',
                  amount: group.notSent,
                  icon: Icons.drafts_rounded,
                  iconColor: _pendingFg,
                  iconBg: _pendingBg,
                ),
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collection progress',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _textMid,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: primaryColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_tileRadius),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textMid,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_fmt(amount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
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

// ─── Payment List ─────────────────────────────────────────────────────────────

class _PaymentList extends StatelessWidget {
  final List<CollectorPayment> payments;
  const _PaymentList({required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(Icons.payments_outlined, size: 32, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No payments recorded',
              style: GoogleFonts.inter(fontSize: 13, color: _textMid),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          ...payments.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentListItem(payment: p),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentListItem extends ConsumerStatefulWidget {
  final CollectorPayment payment;
  const _PaymentListItem({required this.payment});

  @override
  ConsumerState<_PaymentListItem> createState() => _PaymentListItemState();
}

class _PaymentListItemState extends ConsumerState<_PaymentListItem> {
  bool _isLoading = false;

  Future<void> _handleResend() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.resendPayment(widget.payment.paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment resent to admin successfully ✅'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      ref.invalidate(collectorCollectionsProvider);
      ref.invalidate(collectorDashboardProvider);
      ref.invalidate(todayCollectionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Payment?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone. Are you sure you want to delete this payment draft?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deletePayment(widget.payment.paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment deleted successfully ✅'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      ref.invalidate(collectorCollectionsProvider);
      ref.invalidate(collectorDashboardProvider);
      ref.invalidate(todayCollectionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final isSent = payment.sentToAdmin;
    final isRejected = payment.adminStatus.toLowerCase() == 'rejected';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_tileRadius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 👤 Avatar (consistent with your design)
          _InitialsAvatar(name: payment.memberName),
          const SizedBox(width: 12),

          /// 📄 Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Name
                Text(
                  payment.memberName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),

                const SizedBox(height: 6),

                /// Amount + Date
                Row(
                  children: [
                    Text(
                      '₹${_fmt(payment.amount)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDate(payment.paidDate),
                      style: GoogleFonts.inter(fontSize: 11, color: _textMid),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 📌 Status + Action
          if (isRejected)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _rejectedBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _rejectedFg.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Rejected',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _rejectedFg,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleResend,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF5A4100),
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: Color(0xFF5A4100),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            _isLoading ? 'Resending...' : 'Resend',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5A4100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (isSent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFBFDBFE).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sent',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _pendingBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _pendingFg.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Draft',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _pendingFg,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _rejectedBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _rejectedFg.withOpacity(0.2)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _rejectedFg,
                              ),
                            ),
                          )
                          : const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: _rejectedFg,
                          ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MemberHistoryDetailCard
// ─────────────────────────────────────────────────────────────────────────────

class MemberHistoryDetailCard extends StatelessWidget {
  final MemberHistoryResponse history;
  final bool showHeader;

  const MemberHistoryDetailCard({
    super.key,
    required this.history,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          _MemberInfoSection(member: history.member),
          const SizedBox(height: 20),
        ],
        _MemberSummaryGrid(summary: history.summary),
        const SizedBox(height: 24),
        MonthWiseStatusSection(monthWise: history.monthWise),
        const SizedBox(height: 24),
        _PaymentHistoryHeader(count: history.payments.length),
        const SizedBox(height: 12),
        if (history.payments.isEmpty)
          _EmptyPayments()
        else
          _MemberPaymentListTable(payments: history.payments),
      ],
    );
  }
}

class _MemberPaymentListTable extends StatelessWidget {
  final List<PaymentHistoryItem> payments;
  const _MemberPaymentListTable({required this.payments});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDED6F9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            color: const Color(0xFFEEF2FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'AMOUNT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4338CA),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'DATE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4338CA),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'METHOD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4338CA),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'COLLECTED BY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4338CA),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEAEDF2)),
            itemBuilder: (_, i) => MemberPaymentItem(payment: payments[i]),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryHeader extends StatelessWidget {
  final int count;
  const _PaymentHistoryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Payment History',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count payments',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surfaceDim,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 36,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No payments found',
              style: GoogleFonts.inter(
                color: _textMid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MemberHistoryInfoCard (external-use gradient header)
// ─────────────────────────────────────────────────────────────────────────────

class MemberHistoryInfoCard extends StatelessWidget {
  final String name;
  final String phone;
  final int id;

  const MemberHistoryInfoCard({
    super.key,
    required this.name,
    required this.phone,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return _MemberGradientCard(name: name, phone: phone, idLabel: '#$id');
  }
}

class _MemberInfoSection extends StatelessWidget {
  final MemberInfo member;
  const _MemberInfoSection({required this.member});

  @override
  Widget build(BuildContext context) {
    return _MemberGradientCard(
      name: member.name,
      phone: member.phone,
      idLabel: 'ID ${member.id}',
    );
  }
}

class _MemberGradientCard extends StatelessWidget {
  final String name;
  final String phone;
  final String idLabel;

  const _MemberGradientCard({
    required this.name,
    required this.phone,
    required this.idLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      phone,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              idLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member Summary Grid
// ─────────────────────────────────────────────────────────────────────────────

class _MemberSummaryGrid extends StatelessWidget {
  final PaymentSummary summary;
  const _MemberSummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final paidRatio = summary.totalKuriAmount > 0
        ? (summary.totalPaid / summary.totalKuriAmount).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        // 2×2 stat cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Kuri',
                value: '₹${_fmt(summary.totalKuriAmount)}',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF6366F1),
                iconBg: const Color(0xFFEEF2FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Duration',
                value: '${summary.totalMonths} mo',
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF5F3FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Monthly',
                value: '₹${_fmt(summary.monthlyAmount)}',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Paid to Date',
                value: '₹${_fmt(summary.totalPaid)}',
                icon: Icons.check_circle_rounded,
                iconColor: _approvedFg,
                iconBg: _approvedBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pending amount panel
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: summary.pendingAmount > 0
                ? const Color(0xFFFFF8E6)
                : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(_tileRadius),
            border: Border.all(
              color: summary.pendingAmount > 0
                  ? const Color(0xFFFFEDD5)
                  : const Color(0xFFD1FAE5),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: summary.pendingAmount > 0
                          ? const Color(0xFFFEF3C7)
                          : _approvedBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      summary.pendingAmount > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                      color: summary.pendingAmount > 0
                          ? _pendingFg
                          : _approvedFg,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.pendingAmount > 0
                              ? 'PENDING AMOUNT'
                              : 'ALL CLEAR',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: summary.pendingAmount > 0
                                ? _pendingFg
                                : _approvedFg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.pendingAmount > 0
                              ? '₹${summary.pendingAmount.toStringAsFixed(2)}'
                              : 'No dues pending',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: summary.pendingAmount > 0
                                ? const Color(0xFF9A3412)
                                : _approvedFg,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DueBadge(isDue: summary.pendingAmount > 0),
                ],
              ),

              // Progress bar
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment progress',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _textMid,
                        ),
                      ),
                      Text(
                        '${(paidRatio * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: paidRatio,
                      minHeight: 7,
                      backgroundColor: primaryColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_tileRadius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
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
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final bool isDue;
  const _DueBadge({required this.isDue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDue ? _rejectedBg : _approvedBg,
        borderRadius: BorderRadius.circular(_badgeRadius),
        border: Border.all(
          color: isDue
              ? _rejectedFg.withOpacity(0.3)
              : _approvedFg.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDue ? _rejectedFg : _approvedFg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isDue ? 'DUE' : 'CLEAR',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDue ? _rejectedFg : _approvedFg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month-wise breakdown
// ─────────────────────────────────────────────────────────────────────────────

class MonthWiseStatusSection extends StatelessWidget {
  final List<MonthWiseHistoryItem> monthWise;
  const MonthWiseStatusSection({super.key, required this.monthWise});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Installment Breakdown',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 14),
        ...monthWise.asMap().entries.map(
          (e) => _MonthStatusCard(item: e.value, position: e.key),
        ),
      ],
    );
  }
}

class _MonthStatusCard extends StatelessWidget {
  final MonthWiseHistoryItem item;
  final int position;
  const _MonthStatusCard({required this.item, required this.position});

  @override
  Widget build(BuildContext context) {
    final paidRatio = item.target > 0
        ? (item.received / item.target).clamp(0.0, 1.0)
        : 0.0;

    final statusInfo = _monthStatusInfo(item.status, item.isAdvance);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_tileRadius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Month number bubble
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusInfo.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${item.month}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: statusInfo.fg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Month ${item.month}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    if (item.isAdvance) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _pendingBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADVANCE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _pendingFg,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                // Mini progress
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: paidRatio,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusInfo.fg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${_fmt(item.received)} / ₹${_fmt(item.target)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: _textMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status badge
          _MonthBadge(info: statusInfo),
        ],
      ),
    );
  }
}

class _MonthBadge extends StatelessWidget {
  final _StatusInfo info;
  const _MonthBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(_badgeRadius),
      ),
      child: Text(
        info.label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: info.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member Payment Item
// ─────────────────────────────────────────────────────────────────────────────

class MemberPaymentItem extends StatelessWidget {
  final PaymentHistoryItem payment;
  const MemberPaymentItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final isCash = payment.paymentMethod.toString().toLowerCase() == 'cash';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AMOUNT
          Expanded(
            flex: 3,
            child: Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),

          // DATE
          Expanded(
            flex: 3,
            child: Text(
              _formatDate(payment.paidDate),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textMid,
              ),
            ),
          ),

          // METHOD
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCash
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.paymentMethod.toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCash
                        ? const Color(0xFF065F46)
                        : const Color(0xFF4338CA),
                  ),
                ),
              ),
            ),
          ),

          // COLLECTED BY
          Expanded(
            flex: 3,
            child: Text(
              payment.collectedBy,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textMid,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers & micro-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
  ];

  Color get _bg =>
      _colors[name.isEmpty ? 0 : name.codeUnitAt(0) % _colors.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _bg,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg, fg;
    if (s == 'approved') {
      bg = _approvedBg;
      fg = _approvedFg;
    } else if (s == 'rejected') {
      bg = _rejectedBg;
      fg = _rejectedFg;
    } else {
      bg = _pendingBg;
      fg = _pendingFg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.isEmpty
            ? 'Pending'
            : '${status[0].toUpperCase()}${status.substring(1)}',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status helper ────────────────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusInfo(this.label, this.bg, this.fg);
}

_StatusInfo _monthStatusInfo(String status, bool isAdvance) {
  if (isAdvance) return const _StatusInfo('Advance', _pendingBg, _pendingFg);
  final s = status.toLowerCase();
  if (s == 'paid' || s.contains('full')) {
    return const _StatusInfo('Full Paid', _approvedBg, _approvedFg);
  }
  if (s == 'partial') {
    return _StatusInfo(
      'Partial',
      const Color(0xFFEFF6FF),
      const Color(0xFF3B82F6),
    );
  }
  return const _StatusInfo('Pending', _rejectedBg, _rejectedFg);
}

// ─── Formatters ───────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v >= 1000) {
    return NumberFormat('#,##0.##').format(v);
  }
  return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
}

String _formatDate(String dateStr) {
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
  } catch (_) {
    return dateStr;
  }
}
