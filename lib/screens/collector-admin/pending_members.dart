import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/collector/pending_member_model.dart';

class Pendingmembers extends ConsumerWidget {
  const Pendingmembers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingMembersAsyncValue = ref.watch(pendingMembersProvider);

    // Main Brand Colors
    const darkBlue = Color(0xFF2B3A4A);
    const bgGrey = Color(0xFFF2F4F7);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: darkBlue,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pending Dues',
          style: GoogleFonts.poppins(
            color: darkBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: pendingMembersAsyncValue.when(
        data: (data) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: data.members.length,
          separatorBuilder: (_, _) => const SizedBox(height: 20),
          itemBuilder: (context, index) =>
              _buildTwoToneCard(data.members[index]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildTwoToneCard(PendingMember member) {
    const redColor = Color(0xFFDC3545);
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
              color: redColor.withValues(
                alpha: 0.04,
              ), // Very light red background
              border: Border(
                top: BorderSide(color: redColor.withValues(alpha: 0.05)),
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
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: redColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Payment Pending",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: redColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                // Amount
                Text(
                  "₹${member.due.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: redColor,
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
