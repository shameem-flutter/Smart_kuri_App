import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/member/member_dashboard_model.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsyncValue = ref.watch(memberDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8), // Soft, cool off-white
      body: dashboardAsyncValue.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberDashboardProvider);
            await ref
                .read(memberDashboardProvider.future)
                .catchError((_) => data);
          },
          color: primaryColor,
          child: _BentoDashboardLayout(data: data),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _BentoDashboardLayout extends StatelessWidget {
  final MemberDashboardResponse data;

  const _BentoDashboardLayout({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _buildGreetingHeader(data),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildWinnerBento(data.isWinner),
              const SizedBox(height: 16),
              _buildMainFundBento(data),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSquareBento(
                      title: 'Total Paid',
                      amount: data.totalPaid,
                      icon: Icons.done_all_rounded,
                      color: const Color(0xFF059669), // Emerald
                      bgColor: const Color(0xFFD1FAE5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSquareBento(
                      title: 'Remaining',
                      amount: data.remaining,
                      icon: Icons.hourglass_empty_rounded,
                      color: const Color(0xFFD97706), // Amber
                      bgColor: const Color(0xFFFEF3C7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAuctionBento(data.latestAuction),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingHeader(MemberDashboardResponse data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hi, ${data.member.name.split(' ').first} 👋',
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.notifications_none_rounded, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildWinnerBento(bool isWinner) {
    if (!isWinner) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFFACC15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFACC15).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFF854D0E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auction Winner!',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF854D0E),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'You have claimed the pot in this group.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF854D0E).withValues(alpha: 0.8),
                    fontSize: 12,
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

  Widget _buildMainFundBento(MemberDashboardResponse data) {
    final paidPercent = data.totalAmount > 0
        ? (data.totalPaid / data.totalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.member.groupName,
                    style: GoogleFonts.inter(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Value',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${data.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F172A),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          // Circular Progress instead of Linear for a different visual anchor
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: paidPercent,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: primaryColor,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(paidPercent * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareBento({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionBento(dynamic latestAuction) {
    final hasAuction = latestAuction != null;
    final title = hasAuction
        ? (latestAuction['title'] ?? 'Group Auction')
        : 'No Auctions Scheduled';
    final date = hasAuction
        ? (latestAuction['auction_date'] ?? 'TBD')
        : 'Check back later';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hasAuction
                  ? primaryColor.withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasAuction
                  ? Icons.calendar_month_rounded
                  : Icons.event_busy_rounded,
              color: hasAuction ? primaryColor : const Color(0xFF94A3B8),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Event',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    color: hasAuction ? primaryColor : const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hasAuction)
            Icon(
              Icons.arrow_forward_rounded,
              color: const Color(0xFFCBD5E1),
              size: 24,
            ),
        ],
      ),
    );
  }
}
