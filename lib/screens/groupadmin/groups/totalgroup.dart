import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuri_app/models/groupadmin/group_model.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/screens/groupadmin/groups/groupcreate.dart';
import 'package:kuri_app/screens/groupadmin/groups/groupdetails.dart';
import 'package:kuri_app/models/groupadmin/dashboard_model.dart';
import 'package:google_fonts/google_fonts.dart';

const _kPrimary = Color(0xFF1A56DB);
const _kPrimaryLight = Color(0xFFEEF4FF);
const _kOrange = Color(0xFFF59E0B);
const _kOrangeBg = Color(0xFFFFFBEB);
const _kGreen = Color(0xFF10B981);
const _kGreenBg = Color(0xFFECFDF5);
const _kSurface = Color(0xFFFFFFFF);
const _kText = Color(0xFF111827);
const _kSubtext = Color(0xFF6B7280);
const _kDivider = Color(0xFFF3F4F6);

class TotalGroupScreen extends ConsumerWidget {
  const TotalGroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupListAsync = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _kText,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Your Groups',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _kText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: _kText),
                    onPressed: () => ref.invalidate(groupListProvider),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: groupListAsync.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                data: (groupList) {
                  if (groupList.groups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _kPrimaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group_off_rounded,
                              size: 48,
                              color: _kPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No groups available',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You haven't added any groups yet.",
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: _kSubtext,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GroupcreateScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              'Create Group',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: groupList.groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final group = groupList.groups[index];
                      return _GroupListCard(group: group);
                    },
                  );
                },
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! Something went wrong',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          error.toString(),
                          style: GoogleFonts.dmSans(
                            color: _kSubtext,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => ref.invalidate(groupListProvider),
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────

class _GroupListCard extends StatelessWidget {
  final Group group;
  const _GroupListCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final initials = group.name.trim().isEmpty
        ? 'NA'
        : group.name.trim().substring(0, 2).toUpperCase();

    // Simple progress placeholder — replace with real value if available
    const double progress = 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccentHeader(
              initials: initials,
              name: group.name,
              id: group.id.toString(),
              isActive: true,
              progress: progress,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  _DetailGrid(
                    startDate: group.startDate,
                    duration: '${group.durationMonths} Months',
                    amount: '₹${group.monthlyAmount.toStringAsFixed(0)}',
                    collector: "${group.parentGroup}",
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.bar_chart_rounded,
                        label: 'View',
                        foreground: _kPrimary,
                        background: _kPrimaryLight,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupDetailsScreen(groupId: group.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        foreground: _kOrange,
                        background: _kOrangeBg,
                        onTap: () {
                          final dashboardGroup = DashboardGroup(
                            id: group.id,
                            name: group.name,
                            code: '', // Not available in Group model
                            isActive:
                                true, // Defaulting as we don't have this field
                            totalMembers: 0, // Not available
                            monthlyAmount: group.monthlyAmount,
                            durationMonths: group.durationMonths,
                            startDate: group.startDate,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GroupcreateScreen(group: dashboardGroup),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Collect',
                        foreground: _kGreen,
                        background: _kGreenBg,
                        onTap: () {}, // wire up collect action
                        flex: 2,
                        filled: true,
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
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _AccentHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String id;
  final bool isActive;
  final double progress;

  const _AccentHeader({
    required this.initials,
    required this.name,
    required this.id,
    required this.isActive,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0F5FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar with circular progress ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: const Color(0xFFE0E9FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _kText,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 12, color: _kSubtext),
                    const SizedBox(width: 2),
                    Text(
                      id,
                      style: GoogleFonts.dmMono(
                        color: _kSubtext,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _StatusChip(isActive: isActive),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? _kGreenBg : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _kGreen.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? _kGreen : _kSubtext,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.dmSans(
              color: isActive ? _kGreen : _kSubtext,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final String startDate;
  final String duration;
  final String amount;
  final String collector;

  const _DetailGrid({
    required this.startDate,
    required this.duration,
    required this.amount,
    required this.collector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.calendar_month_rounded,
                  iconColor: _kPrimary,
                  label: 'Start Date',
                  value: startDate,
                ),
              ),
              Container(width: 1, height: 40, color: _kDivider),
              Expanded(
                child: _DetailItem(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: _kOrange,
                  label: 'Duration',
                  value: duration,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _kDivider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.payments_rounded,
                  iconColor: _kGreen,
                  label: 'Monthly Amt.',
                  value: amount,
                ),
              ),
              Container(width: 1, height: 40, color: _kDivider),
              Expanded(
                child: _DetailItem(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF9333EA),
                  label: 'Collector',
                  value: collector,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _DetailItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isEnd = align == CrossAxisAlignment.end;
    return Padding(
      padding: EdgeInsets.only(left: isEnd ? 16 : 0, right: isEnd ? 0 : 16),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isEnd
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _kSubtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _kText,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;
  final int flex;
  final bool filled;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.flex = 1,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Material(
        color: filled ? foreground : background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: foreground.withValues(alpha: 0.15),
          highlightColor: foreground.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: filled ? Colors.white : foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: filled ? Colors.white : foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
