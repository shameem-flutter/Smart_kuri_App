import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/collector/pending_member_model.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';

class Pendingmembers extends ConsumerWidget {
  const Pendingmembers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingMembersAsyncValue = ref.watch(pendingMembersProvider);
    final currentStatus = ref.watch(pendingMembersStatusProvider);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: blackColor,
            size: 20,
          ),
          onPressed: () =>
              ref.read(collectorScreenIndexProvider.notifier).goTo(0),
        ),
        title: Text(
          'Payment Status',
          style: GoogleFonts.poppins(
            color: blackColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatusToggle(ref, currentStatus),
          Expanded(
            child: pendingMembersAsyncValue.when(
              data: (data) {
                if (data.members.isEmpty) {
                  return _buildEmptyState(currentStatus);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: data.members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 20),
                  itemBuilder: (context, index) =>
                      _buildTwoToneCard(data.members[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => CustomErrorWidget(
                error: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(pendingMembersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(WidgetRef ref, String currentStatus) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _toggleButton(
                ref,
                'Pending',
                'pending',
                currentStatus == 'pending',
                const Color(0xFFDC3545),
              ),
            ),
            Expanded(
              child: _toggleButton(
                ref,
                'Success',
                'success',
                currentStatus == 'success',
                const Color(0xFF28A745),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(
    WidgetRef ref,
    String label,
    String value,
    bool isSelected,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: () =>
          ref.read(pendingMembersStatusProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    final isPending = status == 'pending';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isPending
                  ? Icons.account_balance_wallet_outlined
                  : Icons.check_circle_outline_rounded,
              size: 40,
              color: primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPending ? 'No pending payments' : 'No success payments',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2B3A4A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Everything is up to date!'
                : 'Successful payments will appear here.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoToneCard(PendingMember member) {
    final isSuccess = member.status.toLowerCase() == 'success';
    final statusColor = isSuccess
        ? const Color(0xFF28A745)
        : const Color(0xFFDC3545);
    const darkBlue = Color(0xFF2B3A4A);

    return Container(
      clipBehavior:
          Clip.antiAlias, // Ensures the child containers don't bleed out
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- TOP SECTION: MEMBER INFO ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar Placeholder
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      member.memberName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name & Group
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.memberName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.group,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Month Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    member.month,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM SECTION: FINANCIALS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.04,
              ), // Very light red/green background
              border: Border(
                top: BorderSide(color: statusColor.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.access_time_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isSuccess ? "Payment Success" : "Payment Pending",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: statusColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                // Amount
                Text(
                  isSuccess
                      ? "₹${member.paid.toStringAsFixed(0)}"
                      : "₹${member.due.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
