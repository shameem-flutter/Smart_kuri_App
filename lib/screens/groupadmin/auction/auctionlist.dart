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
import '../../../widgets/custom_error_widget.dart';
import 'spinscreen.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kSurface = Color(0xFFFFFFFF);
const _kBg = Color(0xFFF6F7FB);
const _kText = Color(0xFF1E293B);
const _kSubtext = Color(0xFF94A3B8);
const _kDivider = Color(0xFFF1F5F9);
const _kGreen = Color(0xFF10B981);
const _kGreenBg = Color(0xFFD1FAE5);
const _kAmber = Color(0xFFF59E0B);
const _kAmberBg = Color(0xFFFEF3C7);
const _kBlue = Color(0xFF3B82F6);
const _kBlueBg = Color(0xFFEFF6FF);

// ─── Auction Group Details Screen ────────────────────────────────────────────

class AuctionGroupDetailsScreen extends ConsumerWidget {
  final String groupId;
  const AuctionGroupDetailsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(auctionGroupDetailsProvider(groupId));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () =>
                ref.invalidate(auctionGroupDetailsProvider(groupId)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (data) => _DetailsBody(group: data.group, months: data.months),
        error: (e, _) => CustomErrorWidget(
          error: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(auctionGroupDetailsProvider(groupId)),
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
      ),
    );
  }
}

// ─── Details Body ─────────────────────────────────────────────────────────────

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: _kText,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null) return;

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _kSurface,
        title: Text(
          'Confirm Auction',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _kText,
          ),
        ),
        content: Text(
          'Schedule an auction for $formattedDate?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: _kSubtext,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _kSubtext,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
        'group_id': widget.group.id,
        'auction_date': formattedDate,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auction created successfully!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      ref.invalidate(auctionGroupDetailsProvider(widget.group.id.toString()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create auction: $e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isModifying = false);
    }
  }

  Future<void> _showEditDateDialog(int auctionId) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: _kText,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null) return;

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _kSurface,
        title: Text(
          'Edit Auction Date',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _kText,
          ),
        ),
        content: Text(
          'Change auction date to $formattedDate?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: _kSubtext,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _kSubtext,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isModifying = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.editAuctionDate(
        groupId: widget.group.id,
        auctionId: auctionId,
        newDate: formattedDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Auction date updated successfully!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      ref.invalidate(auctionGroupDetailsProvider(widget.group.id.toString()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update date: $e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        // ── Hero Header ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group name & duration
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                vertGap(4),
                Text(
                  '${group.durationMonths}-month auction group',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                vertGap(16),

                // Stats Row
                Row(
                  children: [
                    _HeaderStatChip(
                      icon: Icons.calendar_month_rounded,
                      label: '${months.length} months',
                    ),
                    horiGap(8),
                    _HeaderStatChip(
                      icon: Icons.check_circle_outline_rounded,
                      label:
                          '${months.where((m) => m.auction != null).length} scheduled',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Add Auction + Section Label ────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auction Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                // _AddAuctionButton(
                //   isLoading: _isModifying,
                //   onTap: _showAddAuctionDialog,
                // ),
              ],
            ),
          ),
        ),

        // ── Month Cards ────────────────────────────────────────────────
        if (months.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_note_outlined,
                      size: 40,
                      color: primaryColor.withValues(alpha: 0.45),
                    ),
                  ),
                  vertGap(14),
                  Text(
                    'No auction months found',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kSubtext,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _MonthCard(
                  month: months[index],
                  groupId: group.id.toString(),
                  startDate: group.startDate,
                  onAddAuction: _showAddAuctionDialog,
                  onEditDate: _showEditDateDialog,
                ),
                childCount: months.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Header Stat Chip ─────────────────────────────────────────────────────────

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          horiGap(5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Auction Button ───────────────────────────────────────────────────────

// class _AddAuctionButton extends StatelessWidget {
//   final bool isLoading;
//   final VoidCallback onTap;
//   const _AddAuctionButton({required this.isLoading, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
//         decoration: BoxDecoration(
//           color: primaryColor,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (isLoading)
//               const SizedBox(
//                 width: 14,
//                 height: 14,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               )
//             else
//               const Icon(Icons.add_rounded, size: 16, color: Colors.white),
//             horiGap(6),
//             Text(
//               'Add Auction',
//               style: GoogleFonts.poppins(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ─── Month Card ───────────────────────────────────────────────────────────────

class _MonthCard extends ConsumerWidget {
  final AuctionMonth month;
  final String groupId;
  final String? startDate;
  final VoidCallback onAddAuction;
  final Function(int)? onEditDate;

  const _MonthCard({
    required this.month,
    required this.groupId,
    this.startDate,
    required this.onAddAuction,
    this.onEditDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = month.auction;
    final isScheduled = detail != null;

    final String status = !isScheduled
        ? 'Pending'
        : detail.isClosed
        ? 'Closed'
        : 'Active';

    DateTime? expectedDate;
    if (startDate != null) {
      try {
        final base = DateTime.parse(startDate!);
        expectedDate = DateTime(
          base.year,
          base.month + (month.monthNo - 1),
          base.day,
        );
      } catch (_) {}
    }

    String dateStr = 'Not scheduled';
    bool isAuto = false;

    if (isScheduled && detail.auctionDate != null) {
      try {
        dateStr = DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.parse(detail.auctionDate!));
      } catch (_) {
        dateStr = detail.auctionDate!;
      }
    } else if (expectedDate != null) {
      dateStr = '${DateFormat('dd MMM yyyy').format(expectedDate)} (Auto)';
      isAuto = true;
    }

    final winner = (detail?.winner != null && detail!.winner!.isNotEmpty)
        ? detail.winner!
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${month.monthNo}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
                horiGap(12),

                // Date & Winner
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month ${month.monthNo}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                      ),
                      vertGap(3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: isAuto ? _kSubtext : primaryColor,
                          ),
                          horiGap(5),
                          Flexible(
                            child: Text(
                              dateStr,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isAuto ? _kSubtext : _kText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      vertGap(3),
                      Row(
                        children: [
                          Icon(
                            winner != null
                                ? Icons.emoji_events_outlined
                                : Icons.person_outline_rounded,
                            size: 13,
                            color: _kSubtext,
                          ),
                          horiGap(5),
                          Flexible(
                            child: Text(
                              winner ??
                                  (detail == null
                                      ? 'Pending auction'
                                      : 'No winner yet'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _kSubtext,
                                fontStyle: winner == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                _StatusBadge(
                  status: isScheduled
                      ? (status == 'Pending' ? 'UPCOMING' : status)
                      : 'EMPTY',
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: _kDivider),

          // ── Card Footer ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isScheduled) ...[
                  if (expectedDate != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('dd-MM-yyyy').format(expectedDate),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    horiGap(8),
                  ],
                  _ActionBtn(
                    label: 'Set Date',
                    icon: Icons.calendar_month_rounded,
                    bgColor: _kGreen,
                    textColor: Colors.white,
                    onTap: onAddAuction,
                  ),
                ] else ...[
                  _ActionBtn(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    bgColor: const Color(0xFFF1F5F9),
                    textColor: _kText,
                    onTap: () => _showAuctionDetailsBottomSheet(
                      context,
                      detail.id,
                      groupId,
                      onEditDate,
                    ),
                  ),
                  if (!detail.isClosed) ...[
                    horiGap(8),
                    _ActionBtn(
                      label: 'Edit',
                      icon: Icons.edit_calendar_rounded,
                      bgColor: _kAmber,
                      textColor: Colors.white,
                      onTap: () => onEditDate?.call(detail.id),
                    ),
                    if (detail.auctionDate != null &&
                        detail.auctionDate!.isNotEmpty) ...[
                      horiGap(8),
                      _ActionBtn(
                        label: 'Spin',
                        icon: Icons.rotate_right_rounded,
                        bgColor: primaryColor,
                        textColor: Colors.white,
                        onTap: () async {
                          final now = DateTime.now();
                          final auctionDate = DateTime.tryParse(
                            detail.auctionDate ?? '',
                          );

                          if (auctionDate != null) {
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final target = DateTime(
                              auctionDate.year,
                              auctionDate.month,
                              auctionDate.day,
                            );

                            if (target.isAfter(today)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Auction date is yet to come (${DateFormat('dd MMM yyyy').format(target)})',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: _kAmber,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpinScreen(
                                auctionId: detail.id,
                                groupId: groupId,
                                auctionDate: detail.auctionDate,
                              ),
                            ),
                          );
                          ref.invalidate(auctionGroupDetailsProvider(groupId));
                        },
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (status) {
      'Closed' => (_kGreenBg, _kGreen, Icons.check_circle_outline_rounded),
      'Active' => (_kBlueBg, _kBlue, Icons.radio_button_checked_rounded),
      'UPCOMING' => (_kBlueBg, _kBlue, Icons.calendar_month_rounded),
      'EMPTY' => (
        primaryColor.withValues(alpha: 0.08),
        primaryColor,
        Icons.hourglass_empty_rounded,
      ),
      _ => (_kAmberBg, _kAmber, Icons.schedule_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          horiGap(4),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            horiGap(6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Auction Details Bottom Sheet ─────────────────────────────────────────────

void _showAuctionDetailsBottomSheet(
  BuildContext context,
  int auctionId,
  String groupId,
  Function(int)? onEditDate,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final auctionAsync = ref.watch(auctionDetailsProvider(auctionId));

          return auctionAsync.when(
            data: (data) => _AuctionDetailsSheet(
              data: data,
              ref: ref,
              groupId: groupId,
              onEditDate: onEditDate,
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SizedBox(
              height: 200,
              child: CustomErrorWidget(
                error: err.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(auctionDetailsProvider(auctionId)),
              ),
            ),
          );
        },
      ),
    ),
  );
}

// ─── Auction Details Sheet Content ───────────────────────────────────────────

class _AuctionDetailsSheet extends StatelessWidget {
  final AuctionDetailsResponse data;
  final WidgetRef ref;
  final String groupId;
  final Function(int)? onEditDate;

  const _AuctionDetailsSheet({
    required this.data,
    required this.ref,
    required this.groupId,
    this.onEditDate,
  });

  @override
  Widget build(BuildContext context) {
    String dateStr = data.auctionDate ?? 'Not set';
    if (data.auctionDate != null) {
      try {
        dateStr = DateFormat(
          'MMM. dd, yyyy',
        ).format(DateTime.parse(data.auctionDate!));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ── Title ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.gavel_rounded, color: primaryColor, size: 18),
              ),
              horiGap(12),
              Text(
                'Auction Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
            ],
          ),
          vertGap(24),

          // ── Detail Rows ──
          _DetailRow(label: 'Group', value: data.group),
          _DetailRow(label: 'Date', value: dateStr),
          _DetailRow(
            label: 'Winner',
            value: data.isClosed && data.winner != null
                ? data.winner!.name
                : 'Not yet spun',
            showDivider: false,
          ),
          vertGap(24),

          // ── Spin & Edit Buttons ──
          if (!data.isClosed) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEditDate?.call(data.id);
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    label: Text(
                      'Edit Date',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                horiGap(12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpinScreen(
                            auctionId: data.id,
                            groupId: groupId,
                          ),
                        ),
                      );
                      ref.invalidate(auctionGroupDetailsProvider(groupId));
                    },
                    icon: const Text('🎯', style: TextStyle(fontSize: 16)),
                    label: Text(
                      'Spin Now',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kSubtext,
                  ),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: _kDivider),
      ],
    );
  }
}
