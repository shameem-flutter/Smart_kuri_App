import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kuri_app/models/member/member_payments_model.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';

class MemberPaymentHistoryScreen extends ConsumerWidget {
  const MemberPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(memberPaymentsProvider);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: bgGrey,
      body: paymentsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (e, _) => CustomErrorWidget(
          error: e.toString().replaceAll('Exception: ', ''),
          onRetryFuture: () async {
            ref.invalidate(memberPaymentsProvider);
            try {
              await ref.read(memberPaymentsProvider.future);
            } catch (_) {}
          },
        ),
        data: (data) {
          final grouped = _groupByMonth(data.payments);
          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async => ref.invalidate(memberPaymentsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Stylized top bar ──────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Row(
                          children: [
                            // Back button
                            Builder(
                              builder: (ctx) => _NavCircleButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.of(ctx).maybePop(),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Payment History',
                              style: GoogleFonts.poppins(
                                color: blackColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            // Filter/Settings button
                            _NavCircleButton(
                              icon: Icons.tune_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Summary card ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _SummaryCard(data: data),
                  ),
                ),

                // ── List ─────────────────────────────────────
                if (data.payments.isEmpty)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final entry = grouped.entries.elementAt(i);
                        return _MonthSection(
                          month: entry.key,
                          payments: entry.value,
                        );
                      }, childCount: grouped.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, List<MemberPayment>> _groupByMonth(List<MemberPayment> list) {
    final Map<String, List<MemberPayment>> map = {};
    for (final p in list) {
      try {
        final key = DateFormat('MMMM yyyy').format(DateTime.parse(p.paidDate));
        map.putIfAbsent(key, () => []).add(p);
      } catch (_) {
        map.putIfAbsent('Other', () => []).add(p);
      }
    }
    return map;
  }
}

// ─── Summary Card ─────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final MemberPaymentsResponse data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final success = data.payments
        .where((p) => p.paymentStatus.toLowerCase() == 'success')
        .length;
    final pending = data.payments.length - success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Paid',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(data.totalPaid),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Pill(
                label: '${data.payments.length} Total',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: '$success Success',
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              if (pending > 0)
                _Pill(label: '$pending Pending', icon: Icons.schedule_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Pill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month Section ────────────────────────────────────────────
class _MonthSection extends StatelessWidget {
  final String month;
  final List<MemberPayment> payments;
  const _MonthSection({required this.month, required this.payments});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final total = payments.fold(0.0, (s, p) => s + p.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Row(
            children: [
              Text(
                month.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                fmt.format(total),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(payments.length, (i) {
              final isLast = i == payments.length - 1;
              return Column(
                children: [
                  _PaymentRow(payment: payments[i]),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: Colors.grey[100],
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Payment Row ──────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  final MemberPayment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final isSuccess = payment.paymentStatus.toLowerCase() == 'success';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _methodIcon(payment.paymentMethod),
              color: primaryColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),

          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_fmtDate(payment.paidDate)} · ${payment.collectedByName}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Amount + status dot
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(payment.amount),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSuccess ? 'Success' : 'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isSuccess
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'UPI':
        return Icons.account_balance_rounded;
      case 'CASH':
        return Icons.payments_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'BANK TRANSFER':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  String _fmtDate(String raw) {
    try {
      return DateFormat('dd MMM').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────
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
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No payments yet',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your payment history will appear here.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────
class _NavCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
