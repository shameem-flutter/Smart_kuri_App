import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart'; // Ensure this exists
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/groupadmin/member_history_model.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';
import 'package:intl/intl.dart';

class Paymenthistory extends ConsumerStatefulWidget {
  const Paymenthistory({super.key});

  @override
  ConsumerState<Paymenthistory> createState() => _PaymenthistoryState();
}

class _PaymenthistoryState extends ConsumerState<Paymenthistory> {
  @override
  Widget build(BuildContext context) {
    final memberId = ref.watch(paymentHistoryMemberIdProvider);
    final historyData = ref.watch(memberHistoryProvider(memberId));

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => ref
              .read(collectorScreenIndexProvider.notifier)
              .goTo(1), // Back to Assignedmember
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: whiteColor,
            size: 18,
          ),
        ),
        title: Text(
          'Payment History',
          style: GoogleFonts.poppins(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: historyData.when(
        data: (data) {
          if (memberId == 0) return const Center(child: Text("Invalid Member"));
          return _buildContent(context, data, memberId);
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (error, stack) => CustomErrorWidget(
          error: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(memberHistoryProvider(memberId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MemberHistoryResponse data,
    int memberId,
  ) {
    final fmt = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    ); // Clean format
    final double totalKuri = data.summary.totalKuriAmount;
    final double paid = data.summary.totalPaid;
    final double progress = totalKuri > 0
        ? (paid / totalKuri).clamp(0.0, 1.0)
        : 0;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        return ref.refresh(memberHistoryProvider(memberId).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Member Details ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _initials(data.member.name),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.member.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B3A4A),
                      ),
                    ),
                    Text(
                      '${data.summary.totalMonths} Installments',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: "Monthly Amount : "),
                          TextSpan(
                            text: "${data.summary.monthlyAmount}",
                            style: TextStyle(color: successGreen),
                          ),
                        ],
                      ),

                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Progress Bar ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Progress',
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2B3A4A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[100],
                        color: primaryColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stats Row ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      title: 'Total',
                      value: fmt.format(totalKuri),
                      color: Colors.blue,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      title: 'Paid',
                      value: fmt.format(paid),
                      color: Colors.green,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      title: 'Pending',
                      value: fmt.format(data.summary.pendingAmount),
                      color: Colors.orange,
                      icon: Icons.pending_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── History Title ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2B3A4A),
                    ),
                  ),
                  if (data.payments.isNotEmpty)
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
                        '${data.payments.length}',
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

              // ── Transaction List ───────────────────────────────────────────
              data.payments.isEmpty
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
                              'No transactions found',
                              style: GoogleFonts.inter(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.payments.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(data.payments[index], fmt);
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2B3A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(dynamic payment, NumberFormat fmt) {
    // Parsing logic from your original code
    DateTime dateObj = DateTime.tryParse(payment.paidDate) ?? DateTime.now();
    String formattedDate = DateFormat('MMM dd, yyyy').format(dateObj);
    String method = payment.paymentMethod;

    IconData icon = Icons.payments_rounded;
    if (method.toLowerCase().contains('upi')) icon = Icons.qr_code_rounded;
    if (method.toLowerCase().contains('bank')) {
      icon = Icons.account_balance_rounded;
    }

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
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        title: Text(
          fmt.format(payment.amount),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: const Color(0xFF2B3A4A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 4, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                method,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Paid',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
