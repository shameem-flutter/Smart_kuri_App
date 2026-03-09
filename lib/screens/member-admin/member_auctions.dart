import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/member/member_dashboard_model.dart';
import 'package:kuri_app/utilities/gap_func.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF5F6FA);
const _surface = Color(0xFFFFFFFF);
const _ink = Color(0xFF111827);
const _inkSub = Color(0xFF9CA3AF);
const _badgeBg = Color(0xFFF0F0F5);
const _badgeText = Color(0xFF374151);
const _winBorder = Color(0xFFFFD166);
const _winStar = Color(0xFFFABC2A);
const _green = Color(0xFF16A34A);
const _greenBg = Color(0xFFDCFCE7);
const _upcoming = Color(0xFFF59E0B);
const _upcomingBg = Color(0xFFFFF7E6);
// ─────────────────────────────────────────────────────────────────────────────

class MemberAuctionsScreen extends ConsumerWidget {
  const MemberAuctionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(memberAuctionsProvider);
    final dashboardAsync = ref.watch(memberDashboardProvider);
    final String currentMemberName = dashboardAsync.value?.member.name ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: transparent,
        body: SafeArea(
          bottom: false,
          child: auctionsAsync.when(
            data: (auctions) {
              final completedCount = auctions
                  .where((a) => a.status.toLowerCase() == 'completed')
                  .length;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(memberAuctionsProvider);
                  await ref
                      .read(memberAuctionsProvider.future)
                      .catchError((_) => auctions);
                },
                color: primaryColor,
                backgroundColor: _surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: _buildHeader(
                        context,
                        auctions.length,
                        completedCount,
                      ),
                    ),

                    if (auctions.isEmpty)
                      const SliverFillRemaining(child: _EmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AuctionCard(
                                item: auctions[i],
                                currentMemberName: currentMemberName,
                              ),
                            ),
                            childCount: auctions.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => Column(
              children: [
                _buildHeader(context, null, null),
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              ],
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading auctions:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int? total, int? completed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nav row ──
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: _ink,
                  ),
                ),
              ),
              const Spacer(),
              if (total != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$completed of $total done',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Title block ──
          Text(
            'Auctions',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            total == null
                ? 'Loading...'
                : total == 0
                ? 'No auctions scheduled yet'
                : '$total auctions in this cycle',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _inkSub,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({required this.item, required this.currentMemberName});

  final AuctionItem item;
  final String currentMemberName;

  @override
  Widget build(BuildContext context) {
    final bool isMyWin =
        currentMemberName.isNotEmpty &&
        item.winnerName.toLowerCase() == currentMemberName.toLowerCase();
    final bool hasWinner = item.winnerName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMyWin ? _winBorder : const Color(0xFFEDEDF2),
          width: isMyWin ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Month Badge ──
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _badgeBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'M${item.monthNo}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _badgeText,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Main content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasWinner ? 'Winner: ${item.winnerName}' : 'Upcoming Auction',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      item.formattedDate,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _inkSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                vertGap(5),
                if (item.winnerToken != null) ...[
                  Text(
                    'Token #${item.winnerToken}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _inkSub,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Star ──
          if (isMyWin) ...[
            const SizedBox(width: 8),
            const Icon(Icons.star_rounded, color: _winStar, size: 20),
          ],

          const SizedBox(width: 8),

          _StatusChip(status: item.status),
        ],
      ),
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool done = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done ? _greenBg : _upcomingBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: done ? _green : _upcoming,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _badgeBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gavel_rounded, color: _badgeText, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            'No Auctions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No auctions have been scheduled yet.',
            style: GoogleFonts.inter(fontSize: 13, color: _inkSub),
          ),
        ],
      ),
    );
  }
}
