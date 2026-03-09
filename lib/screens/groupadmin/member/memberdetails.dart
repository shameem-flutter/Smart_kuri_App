import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/groupadmin/member_details_model.dart';
import '../../../providers/group_provider.dart';
import '../../../widgets/custom_error_widget.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF0F4FF);
const _surface = Color(0xFFFFFFFF);
const _primary = Color(0xFF2563EB);
const _primaryDark = Color(0xFF1E40AF);
const _green = Color(0xFF059669);
const _greenSoft = Color(0xFFD1FAE5);
const _amber = Color(0xFFD97706);
const _amberSoft = Color(0xFFFEF3C7);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _divider = Color(0xFFE2E8F0);

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
        // ── Hero SliverAppBar ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: _primaryDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () =>
                  ref.invalidate(memberAdminDetailsProvider(memberId)),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeroCard(data.member),
          ),
        ),

        // ── Body Content ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bento summary row
                _buildBentoSummary(data),
                const SizedBox(height: 28),

                // Member info section
                _sectionLabel('Member Information'),
                const SizedBox(height: 12),
                _buildInfoCard(data),
                const SizedBox(height: 28),

                // Month-wise
                _sectionLabel('Month-wise Payments'),
                const SizedBox(height: 12),
                ...List.generate(data.monthWise.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMonthCard(data.monthWise[i]),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(MemberDetailInfo member) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _heroPill(Icons.group_rounded, member.group),
                          const SizedBox(width: 8),
                          _heroPill(
                            Icons.confirmation_num_rounded,
                            'TKN ${member.tokenNo}',
                          ),
                        ],
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

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bento Summary ─────────────────────────────────────────────────────────
  Widget _buildBentoSummary(MemberDetailsResponse data) {
    return Row(
      children: [
        Expanded(
          child: _BentoCard(
            label: 'Total Paid',
            value: '₹${data.totalCollected.toStringAsFixed(0)}',
            sub: '${data.monthsPaid} months',
            icon: Icons.wallet_rounded,
            iconBg: _greenSoft,
            iconColor: _green,
            accentColor: _green,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BentoCard(
            label: 'Total Due',
            value: '₹${data.totalDue.toStringAsFixed(0)}',
            sub: '${data.durationMonths - data.monthsPaid} months left',
            icon: Icons.hourglass_bottom_rounded,
            iconBg: _amberSoft,
            iconColor: _amber,
            accentColor: _amber,
          ),
        ),
      ],
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard(MemberDetailsResponse data) {
    final rows = [
      _InfoRow('Name', data.member.name),
      _InfoRow('Phone', data.member.phone.isEmpty ? '—' : data.member.phone),
      _InfoRow('Email', data.member.email.isEmpty ? '—' : data.member.email),
      _InfoRow(
        'Address',
        data.member.address.isEmpty ? '—' : data.member.address,
      ),
      _InfoRow(
        'Aadhaar',
        data.member.aadhaarNo.isEmpty ? '—' : data.member.aadhaarNo,
      ),
      _InfoRow('Group', data.member.group),
      _InfoRow('Monthly', '₹${data.monthlyAmount.toStringAsFixed(2)}'),
      _InfoRow(
        'Progress',
        '${data.monthsPaid} / ${data.durationMonths} months',
      ),
      _InfoRow(
        'Status',
        data.member.status,
        valueColor: data.member.status.toLowerCase() == 'active'
            ? _green
            : _amber,
        isLast: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: rows.asMap().entries.map((e) {
            final isEven = e.key.isEven;
            final row = e.value;
            return Container(
              color: isEven ? const Color(0xFFF8FAFF) : _surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      row.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: row.valueColor ?? _ink,
                      ),
                    ),
                  ),
                  if (row.label == 'Status')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.member.status.toLowerCase() == 'active'
                            ? _greenSoft
                            : _amberSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.member.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: data.member.status.toLowerCase() == 'active'
                              ? _green
                              : _amber,
                        ),
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

  // ── Month Card ────────────────────────────────────────────────────────────
  Widget _buildMonthCard(MonthWisePayment item) {
    final isPaid = item.status.toLowerCase() == 'paid';
    final accent = isPaid ? _green : _amber;
    final accentSoft = isPaid ? _greenSoft : _amberSoft;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid
              ? _green.withValues(alpha: 0.12)
              : _amber.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            // Month badge
            Container(
              width: 56,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${item.month}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  height: 1,
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Month ${item.month}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isPaid && item.paidDate != null
                          ? item.paidDate!
                          : 'Payment Pending',
                      style: GoogleFonts.inter(fontSize: 12, color: _muted),
                    ),
                    if (isPaid &&
                        item.collector != null &&
                        item.collector!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.collector!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _muted,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Amount + badge
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.amount != null
                        ? '₹${item.amount!.toStringAsFixed(0)}'
                        : '—',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 11,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? 'PAID' : 'PENDING',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: accent,
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
      ),
    );
  }
}

// ── Data helper ───────────────────────────────────────────────────────────────
class _InfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  const _InfoRow(
    this.label,
    this.value, {
    this.valueColor,
    this.isLast = false,
  });
}

// ── Bento Card ────────────────────────────────────────────────────────────────
class _BentoCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color accentColor;

  const _BentoCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
