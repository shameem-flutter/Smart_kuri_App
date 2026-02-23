import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/screens/groupadmin/groups/groupdetails.dart';
import 'package:kuri_app/screens/groupadmin/groups/groupcreate.dart';
import 'package:kuri_app/utilities/gap_func.dart';
import '../../models/groupadmin/dashboard_model.dart';
import '../../providers/group_provider.dart';

const _kPrimary = Color(0xFF1A56DB);
const _kPrimaryLight = Color(0xFFEEF4FF);
const _kSurface = Color(0xFFFFFFFF);
const _kText = Color(0xFF0F1C2E);
const _kSubtext = Color(0xFF8895A7);
const _kDivider = Color(0xFFF0F3F8);
const _kGreen = Color(0xFF0E9F6E);
const _kGreenBg = Color(0xFFECFDF5);
const _kOrange = Color(0xFFFF7043);
const _kOrangeBg = Color(0xFFFFF3EE);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return dashboardAsync.when(
      data: (dashboardData) => _buildDashboard(context, dashboardData),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $error',
                style: GoogleFonts.inter(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.invalidate(dashboardDataProvider);
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    DashboardResponse dashboardData,
  ) {
    final stats = dashboardData.stats;
    final groups = dashboardData.groups;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Admin",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B3A4A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Here's your collection overview for today.",
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: [
                  _buildStatCard(
                    icon: Icons.inventory_2_rounded,
                    iconColor: Colors.orange,
                    label: 'Total Groups',
                    value: stats.totalGroups.toString(),
                  ),
                  _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: Colors.green,
                    label: 'Active Groups',
                    value: stats.activeGroups.toString(),
                  ),
                  _buildStatCard(
                    icon: Icons.people_alt_rounded,
                    iconColor: Colors.blue,
                    label: 'Total Members',
                    value: stats.totalMembers.toString(),
                  ),
                  _buildStatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: Colors.teal,
                    label: 'This Month',
                    value: '₹${stats.thisMonthCollection}',
                  ),
                  _buildStatCard(
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF2962FF),
                    label: 'Total Collected',
                    value: '₹${stats.totalReceived}',
                  ),
                ],
              ),

              vertGap(40),

              Text(
                'Your Groups',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B3A4A),
                  letterSpacing: -0.5,
                ),
              ),
              vertGap(16),

              if (groups.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No groups found',
                      style: GoogleFonts.inter(color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                ...groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: buildGroupCard(
                      context: context,
                      name: group.name,
                      id: group.id.toString(),
                      startDate: group.startDate,
                      duration: '${group.durationMonths} months',
                      amount: '₹${group.monthlyAmount}',
                      collector: 'Not Assigned', // Not provided in API
                      isActive: group.isActive,
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupcreateScreen(group: group),
                          ),
                        );
                      },
                      onView: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupDetailsScreen(groupId: group.id),
                          ),
                        );
                      },
                      onCollect: () {},
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2B3A4A),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGroupCard({
    required BuildContext context,
    required String name,
    required String id,
    required String startDate,
    required String duration,
    required String amount,
    required String collector,
    required bool isActive,

    double progress = 0.0,
    VoidCallback? onView,
    VoidCallback? onEdit,
    VoidCallback? onCollect,
  }) {
    final initials = name.trim().isEmpty
        ? 'NA'
        : name.trim().substring(0, 2).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A56DB).withValues(alpha: 0.06),
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
              name: name,
              id: id,
              isActive: isActive,
              progress: progress,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  _DetailGrid(
                    startDate: startDate,
                    duration: duration,
                    amount: amount,
                    collector: collector,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _ActionBtn(
                        icon: Icons.bar_chart_rounded,
                        label: 'View',
                        foreground: _kPrimary,
                        background: _kPrimaryLight,
                        onTap: onView ?? () {},
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        foreground: _kOrange,
                        background: _kOrangeBg,
                        onTap: onEdit ?? () {},
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Collect',
                        foreground: _kGreen,
                        background: _kGreenBg,
                        onTap: onCollect ?? () {},
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
                    Icon(Icons.tag_rounded, size: 12, color: _kSubtext),
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
