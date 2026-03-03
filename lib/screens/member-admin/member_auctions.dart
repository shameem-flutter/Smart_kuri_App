import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart';

class MemberAuctionsScreen extends StatelessWidget {
  const MemberAuctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Text(
          'Auctions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Auctions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Active and past auctions will appear here.',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
