import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/groupadmin/member_details_model.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/custom_error_widget.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF4F7FF);
const _surface = Color(0xFFFFFFFF);
const _primary = Color(0xFF2563EB);
const _primaryDark = Color(0xFF1D4ED8);
const _green = Color(0xFF059669);
const _greenSoft = Color(0xFFD1FAE5);
const _amber = Color(0xFFD97706);
const _amberSoft = Color(0xFFFEF3C7);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _rowAlt = Color(0xFFF8FAFF);
const _border = Color(0xFFE2E8F0);

// ── Shared card decoration ────────────────────────────────────────────────────
BoxDecoration _cardDecoration({Color? shadowColor, double radius = 20}) =>
    BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: (shadowColor ?? const Color(0xFF0F172A)).withValues(
            alpha: 0.04,
          ),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _TopBar({required this.onBack, required this.onRefresh});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _refreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _refreshing = true);
    widget.onRefresh();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 10),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: _border.withValues(alpha: 0.8), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          _BarIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: widget.onBack,
          ),
          const SizedBox(width: 14),
          // Title + subtitle
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Member Details',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Profile & payment history',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _refreshing ? null : _handleRefresh,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: _ink, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: _ink, size: 18),
      ),
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class MemberDetailsScreen extends ConsumerWidget {
  final int memberId;
  const MemberDetailsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(memberAdminDetailsProvider(memberId));

    return Scaffold(
      backgroundColor: _bg,
      body: detailsAsync.when(
        data: (data) => _buildBody(context, ref, data),
        error: (err, _) => Scaffold(
          appBar: AppBar(backgroundColor: _bg, elevation: 0),
          body: CustomErrorWidget(
            error: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(memberAdminDetailsProvider(memberId)),
          ),
        ),
        loading: () => const Scaffold(
          backgroundColor: _bg,
          body: Center(child: CircularProgressIndicator(color: _primary)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MemberDetailsResponse data,
  ) {
    return CustomScrollView(
      slivers: [
        // ── Top Bar ───────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          flexibleSpace: _TopBar(
            onBack: () => Navigator.pop(context),
            onRefresh: () =>
                ref.invalidate(memberAdminDetailsProvider(memberId)),
          ),
        ),

        // ── Body ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(data.member),
                const SizedBox(height: 24),

                _sectionLabel('Overview'),
                const SizedBox(height: 12),
                _buildBentoSummary(data),
                const SizedBox(height: 28),

                _sectionLabel('Information'),
                const SizedBox(height: 12),
                _buildInfoCard(data),
                const SizedBox(height: 28),

                _sectionLabel('Timeline & Payments'),
                const SizedBox(height: 12),
                _buildMonthsCard(data.monthWise),
                const SizedBox(height: 28),

                _buildTransactionHistory(data.recentTransactions),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard(MemberDetailInfo member) {
    final isActive = member.status.toLowerCase() == 'active';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.phone.isNotEmpty
                            ? member.phone
                            : 'No Phone Provided',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? _green : _amber,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    member.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                _heroPill(Icons.group_work_rounded, 'Group', member.group),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _heroPill(
                  Icons.confirmation_num_rounded,
                  'Token',
                  'TKN ${member.tokenNo}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            // ← constrains the Column
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bento Summary ─────────────────────────────────────────────────────────
  Widget _buildBentoSummary(MemberDetailsResponse data) {
    final monthsLeft = data.durationMonths - data.monthsPaid;
    final progress = data.durationMonths > 0
        ? data.monthsPaid / data.durationMonths
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                title: 'Total Paid',
                amount: '₹${data.totalCollected.toStringAsFixed(0)}',
                subtitle: '${data.monthsPaid} months',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: _green,
                bgColor: _greenSoft,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _bentoCard(
                title: 'Total Due',
                amount: '₹${data.totalDue.toStringAsFixed(0)}',
                subtitle: '$monthsLeft months left',
                icon: Icons.pending_actions_rounded,
                iconColor: _amber,
                bgColor: _amberSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Progress',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: _border,
                  valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.monthsPaid} of ${data.durationMonths} months completed',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bentoCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _ink,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard(MemberDetailsResponse data) {
    final rows = [
      _InfoRow(Icons.person_outline, 'Name', data.member.name),
      _InfoRow(
        Icons.phone_outlined,
        'Phone',
        data.member.phone.isEmpty ? '—' : data.member.phone,
      ),
      _InfoRow(
        Icons.email_outlined,
        'Email',
        data.member.email.isEmpty ? '—' : data.member.email,
      ),
      _InfoRow(
        Icons.home_outlined,
        'Address',
        data.member.address.isEmpty ? '—' : data.member.address,
      ),
      _InfoRow(
        Icons.badge_outlined,
        'Aadhaar',
        data.member.aadhaarNo.isEmpty ? '—' : data.member.aadhaarNo,
      ),
      _InfoRow(Icons.category_outlined, 'Group', data.member.group),
      _InfoRow(
        Icons.payments_outlined,
        'Monthly',
        '₹${data.monthlyAmount.toStringAsFixed(2)}',
      ),
    ];

    return Container(
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: rows.asMap().entries.map((e) {
            final isEven = e.key.isEven;
            final row = e.value;
            return Container(
              color: isEven ? _surface : _rowAlt,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(row.icon, size: 20, color: _muted),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: Text(
                      row.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Months Card ───────────────────────────────────────────────────────────
  Widget _buildMonthsCard(List<MonthWisePayment> months) {
    return Container(
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: months.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isPaid = item.status.toLowerCase() == 'paid';
            final isLast = i == months.length - 1;

            return Container(
              color: _surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isPaid ? _greenSoft : _amberSoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: isPaid
                              ? const Icon(Icons.check_rounded, color: _green)
                              : Text(
                                  '${item.month}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _amber,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Month ${item.month}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPaid
                                    ? 'Payment Completed'
                                    : 'Awaiting Payment',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              (item.paid != null && item.paid! > 0)
                                  ? '₹${item.paid!.toStringAsFixed(0)}'
                                  : (item.target != null
                                        ? '₹${item.target!.toStringAsFixed(0)}'
                                        : '—'),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isPaid ? 'PAID' : 'PENDING',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isPaid ? _green : _amber,
                              ),
                            ),
                            if (item.isAdvance)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'ADVANCE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: _primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 76,
                      color: _border.withValues(alpha: 0.5),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<RecentTransaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: _ink),
            const SizedBox(width: 10),
            _sectionLabel('Transaction History'),
          ],
        ),
        const SizedBox(height: 16),

        ...transactions.map((item) => _TransactionTile(item: item)),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _ink,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

class _TransactionTile extends StatelessWidget {
  final RecentTransaction item;

  const _TransactionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final String dateStr = _formatDate(item.paidDate);

    final _TransactionStyle style = _getTransactionStyle(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(radius: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            /// 🔹 ICON
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: style.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, size: 20, color: style.iconColor),
            ),

            const SizedBox(width: 12),

            /// 🔹 CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Amount + Payment Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// Date + Collector
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: _muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 12),
                      Container(width: 1, height: 12, color: _border),
                      const SizedBox(width: 12),

                      /// Collector
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Collected by ',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: item.collector,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: _ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Date Formatter (safe)
  String _formatDate(String rawDate) {
    try {
      return DateFormat('d MMM, yyyy').format(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  /// 🔹 Payment Badge

  /// 🔹 Style Logic (Scalable)
  _TransactionStyle _getTransactionStyle(RecentTransaction item) {
    return _TransactionStyle(
      icon: Icons.arrow_downward_rounded,
      iconColor: const Color(0xFF16A34A),
      bgColor: const Color(0xFFECFDF5),
    );
  }
}

class _TransactionStyle {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _TransactionStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
