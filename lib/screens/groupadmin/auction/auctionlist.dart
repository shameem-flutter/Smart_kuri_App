import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/utilities/gap_func.dart';
import '../../../models/groupadmin/auction/auction_group_details_model.dart';
import '../../../models/groupadmin/auction/auction_details_model.dart';
import '../../../providers/auction_provider.dart';
import '../../../providers/group_provider.dart';
import 'spinscreen.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFF59E0B);
const _kOrangeLight = Color(0xFFFEF3C7);
const _kSurface = Color(0xFFFFFFFF);
const _kText = Color(0xFF111827);
const _kSubtext = Color(0xFF6B7280);
const _kDivider = Color(0xFFE5E7EB);
const _kBg = Color(0xFFF8F9FD);

class AuctionGroupDetailsScreen extends ConsumerWidget {
  final String groupId;
  const AuctionGroupDetailsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(auctionGroupDetailsProvider(groupId));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kText),
            onPressed: () =>
                ref.invalidate(auctionGroupDetailsProvider(groupId)),
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (data) {
          return _DetailsBody(group: data.group, months: data.months);
        },
        error: (e, _) => _ErrorView(
          error: e.toString(),
          onRetry: () => ref.refresh(auctionGroupDetailsProvider(groupId).future),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────
class _DetailsBody extends ConsumerStatefulWidget {
  final AuctionGroup group;
  final List<AuctionMonth> months;
  const _DetailsBody({required this.group, required this.months});

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  bool _isModifying = false;

  Future<void> _showAddAuctionDialog() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: _kText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    final formattedDate =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Auction',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: _kText,
          ),
        ),
        content: Text(
          'Are you sure you want to schedule an auction for $formattedDate?',
          style: GoogleFonts.dmSans(fontSize: 15, color: _kSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: _kSubtext,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isModifying = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.createAuction({
        "group_id": widget.group.id,
        "auction_date": formattedDate,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction created successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      ref.invalidate(auctionGroupDetailsProvider(widget.group.id.toString()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create auction: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isModifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final months = widget.months;
    return CustomScrollView(
      slivers: [
        // ── Top section ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _kText,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${group.durationMonths}-month auction group',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _kSubtext,
                            ),
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
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${months.length} months',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Add Auction button
                GestureDetector(
                  onTap: _isModifying ? null : () => _showAddAuctionDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isModifying)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          'Add Auction',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'AUCTION SCHEDULE',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kSubtext,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Month Cards ─────────────────────────────────────────────────
        if (months.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No auction months found.',
                style: GoogleFonts.dmSans(fontSize: 14, color: _kSubtext),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _MonthCard(
                  month: months[index],
                  groupId: group.id.toString(),
                ),
                childCount: months.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Month Card ─────────────────────────────────────────────────────────────
class _MonthCard extends ConsumerWidget {
  final AuctionMonth month;
  final String groupId;
  const _MonthCard({required this.month, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = month.auction;

    final String status = detail == null
        ? 'Pending'
        : detail.isClosed
        ? 'Closed'
        : 'Active';

    String dateStr = 'Not scheduled';
    if (detail?.auctionDate != null) {
      try {
        dateStr = DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.parse(detail!.auctionDate!));
      } catch (_) {
        dateStr = detail!.auctionDate!;
      }
    }

    final winner = (detail?.winner != null && detail!.winner!.isNotEmpty)
        ? detail.winner!
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                // Month number badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${month.monthNo}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Month label + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month ${month.monthNo}',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: _kSubtext,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _kSubtext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: _kDivider),

          // ── Card Footer ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Winner section
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: winner != null
                              ? Colors.green.withValues(alpha: 0.10)
                              : _kDivider,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          winner != null
                              ? Icons.emoji_events_rounded
                              : Icons.person_outline_rounded,
                          size: 16,
                          color: winner != null
                              ? const Color(0xFF15803D)
                              : _kSubtext,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WINNER',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kSubtext,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              winner ??
                                  (detail == null
                                      ? 'No auction yet'
                                      : 'No winner yet'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: winner != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: winner != null ? _kText : _kSubtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons — only shown if auction exists
                if (detail != null) ...[
                  const SizedBox(width: 12),
                  _ActionBtn(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    bgColor: const Color(0xFFEFF6FF),
                    textColor: const Color(0xFF2563EB),
                    onTap: () {
                      _showAuctionDetailsBottomSheet(context, detail.id);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: 'Spin',
                    icon: Icons.rotate_right_rounded,
                    bgColor: const Color(0xFFFFF7ED),
                    textColor: _kOrange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpinScreen(auctionId: detail.id),
                        ),
                      );
                      // Refresh the group details to show the updated winner
                      ref.invalidate(auctionGroupDetailsProvider(groupId));
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (status) {
      'Closed' => (
        Colors.green.withValues(alpha: 0.12),
        const Color(0xFF15803D),
        Icons.check_circle_outline_rounded,
      ),
      'Active' => (
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        Icons.radio_button_checked_rounded,
      ),
      _ => (_kOrangeLight, _kOrange, Icons.schedule_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            status,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _kText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.dmSans(color: _kSubtext, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Retry',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── View Details Bottom Sheet ──────────────────────────────────────────────
void _showAuctionDetailsBottomSheet(BuildContext context, int auctionId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Consumer(
          builder: (context, ref, _) {
            final auctionAsync = ref.watch(auctionDetailsProvider(auctionId));

            return auctionAsync.when(
              data: (data) => _buildAuctionDetailsContent(context, data),
              loading: () => SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),
              error: (err, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error: $err',
                    style: GoogleFonts.dmSans(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _buildAuctionDetailsContent(
  BuildContext context,
  AuctionDetailsResponse data,
) {
  String dateStr = data.auctionDate ?? 'Not set';
  if (data.auctionDate != null) {
    try {
      dateStr = DateFormat(
        'MMM. dd, yyyy',
      ).format(DateTime.parse(data.auctionDate!));
    } catch (_) {}
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Align(
          alignment: Alignment.center,
          child: Text(
            'Auction Details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E3165),
            ),
          ),
        ),
        const SizedBox(height: 22),

        _buildDetailRow('GROUP', data.group),
        _buildDetailRow('DATE', dateStr),
        _buildDetailRow(
          'WINNER',
          data.isClosed && data.winner != null
              ? data.winner!.name
              : 'Not yet spun',
          showDivider: false,
        ),

        const SizedBox(height: 16),

        // Spin Button
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close bottom sheet
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpinScreen(auctionId: data.id)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF333385,
            ), // Custom dark purple matching the button
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF333385).withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Spin Auction',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        vertGap(10),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, {bool showDivider = true}) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
      if (showDivider)
        const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
    ],
  );
}
