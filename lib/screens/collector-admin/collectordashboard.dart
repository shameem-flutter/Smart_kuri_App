import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/groupadmin/collector_dashboard_model.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';
import 'package:intl/intl.dart';
import 'package:kuri_app/screens/collector-admin/collectorprofile.dart'
    as kuri_app_profile;

class Collectordashboard extends ConsumerStatefulWidget {
  const Collectordashboard({super.key});
  @override
  ConsumerState<Collectordashboard> createState() => _CollectordashboardState();
}

class _CollectordashboardState extends ConsumerState<Collectordashboard> {
  @override
  Widget build(BuildContext context) {
    final dashboardData = ref.watch(collectorDashboardProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: dashboardData.when(
        data: (data) => _buildDashboard(context, data),
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (error, stack) => CustomErrorWidget(
          error: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(collectorDashboardProvider),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, CollectorDashboardModel data) {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        return ref.refresh(collectorDashboardProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2B3A4A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const kuri_app_profile.CollectorprofileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Stats Grid ─────────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard(
                    title: 'Today',
                    value: '₹${data.todayCollection}',
                    icon: Icons.today_rounded,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    title: 'Monthly',
                    value: '₹${data.monthlyCollection}',
                    icon: Icons.calendar_month_rounded,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    title: 'Total',
                    value: '₹${data.totalCollection.toStringAsFixed(1)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    title: 'Members',
                    value: '${data.activeMembers}',
                    icon: Icons.people_alt_rounded,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Recent Payments Title ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Payments',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2B3A4A),
                    ),
                  ),
                  if (data.recentPayments.isNotEmpty)
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
                        '${data.recentPayments.length} New',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Payment List ───────────────────────────────────────────────
              data.recentPayments.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recent payments found',
                              style: GoogleFonts.inter(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.recentPayments.length,
                      itemBuilder: (context, index) {
                        final payment = data.recentPayments[index];
                        return _buildPaymentCard(payment);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2B3A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(RecentPayment payment) {
    String formattedDate = payment.date;
    try {
      final DateTime dt = DateTime.parse(payment.date);
      formattedDate = DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {}

    String formattedTime = payment.time;
    try {
      if (payment.time.contains('.')) {
        formattedTime = payment.time.split('.')[0];
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.currency_rupee_rounded,
            color: Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          payment.member,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: const Color(0xFF2B3A4A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$formattedDate • $formattedTime',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        trailing: Text(
          '+ ₹${payment.amount.toStringAsFixed(1)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
