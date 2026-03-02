import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/screens/collector-admin/collectordashboard.dart';
import 'package:kuri_app/screens/collector-admin/assignedmember.dart';
import 'package:kuri_app/screens/collector-admin/collectorprofile.dart';
import 'package:kuri_app/screens/collector-admin/pending_members.dart';
import 'package:kuri_app/screens/collector-admin/collectoraddcollection.dart';
import 'package:kuri_app/screens/collector-admin/today_collections_screen.dart';
import 'package:kuri_app/screens/collector-admin/reports_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/screens/collector-admin/paymenthistory.dart';

class Collectorhomescreen extends ConsumerStatefulWidget {
  const Collectorhomescreen({super.key});

  @override
  ConsumerState<Collectorhomescreen> createState() =>
      _CollectorhomescreenState();
}

class _CollectorhomescreenState extends ConsumerState<Collectorhomescreen> {
  // Define all the screens that will be managed by the IndexedStack
  final List<Widget> _screens = const [
    Collectordashboard(),
    Assignedmember(),
    Pendingmembers(),
    Addcollection(),
    TodayCollectionsScreen(),
    ReportsScreen(),
    CollectorprofileScreen(),
    Paymenthistory(),
  ];

  void _goTo(int index) {
    ref.read(collectorScreenIndexProvider.notifier).goTo(index);
  }

  @override
  Widget build(BuildContext context) {
    // Read the current index from the provider
    final currentIndex = ref.watch(collectorScreenIndexProvider);

    return PopScope(
      canPop: currentIndex == -1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != -1) {
          // If we are showing a sub-screen, pressing back returns to the main menu (-1)
          ref.read(collectorScreenIndexProvider.notifier).goTo(-1);
        }
      },
      child: currentIndex == -1
          ? Scaffold(
              backgroundColor:
                  primaryColor, // Use the brand's dark blue background
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Collector',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _goTo(6),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Navigation List Section
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(
                            0xFFF8F9FD,
                          ), // Light gray background for content
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 30, bottom: 40),
                          child: Column(
                            children: [
                              _MenuOption(
                                title: 'Dashboard',
                                icon: Icons.dashboard_outlined,
                                iconColor: primaryColor,
                                onTap: () => _goTo(0),
                              ),
                              _Divider(),
                              _MenuOption(
                                title: 'Members',
                                icon: Icons.people_outline_rounded,
                                iconColor: Colors.blueAccent,
                                onTap: () => _goTo(1),
                              ),
                              _Divider(),
                              _MenuOption(
                                title: 'Pending',
                                icon: Icons.error_outline_rounded,
                                iconColor: Colors.orange,
                                onTap: () => _goTo(2),
                              ),
                              _Divider(),
                              _MenuOption(
                                title: 'Add Collection',
                                icon: Icons.add_circle_outline_rounded,
                                iconColor: Colors.green,
                                onTap: () => _goTo(3),
                              ),
                              _Divider(),
                              _MenuOption(
                                title: 'Today',
                                icon: Icons.calendar_today_rounded,
                                iconColor: Colors.purple,
                                onTap: () => _goTo(4),
                              ),
                              _Divider(),
                              _MenuOption(
                                title: 'Reports',
                                icon: Icons.auto_graph_rounded,
                                iconColor: Colors.teal,
                                onTap: () => _goTo(5),
                              ),
                              _Divider(),
                              // _MenuOption(
                              //   title: 'Profile',
                              //   icon: Icons.person_outline_rounded,
                              //   iconColor: const Color(0xFF2B3A4A),
                              //   onTap: () => _goTo(6),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : IndexedStack(index: currentIndex, children: _screens),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.withValues(alpha: 0.15),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: iconColor.withValues(alpha: 0.1),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B3A4A),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
