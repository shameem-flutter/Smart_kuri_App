import 'package:flutter/material.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/screens/collector-admin/collectordashboard.dart';
import 'package:kuri_app/screens/collector-admin/assignedmember.dart';
import 'package:kuri_app/screens/collector-admin/collectorprofile.dart';
import 'package:kuri_app/screens/collector-admin/pending_members.dart';
import 'package:kuri_app/screens/collector-admin/collectoraddcollection.dart';
import 'package:kuri_app/screens/collector-admin/today_collections_screen.dart';
import 'package:kuri_app/screens/collector-admin/reports_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/screens/collector-admin/all_collections_screen.dart';

class Collectorhomescreen extends ConsumerStatefulWidget {
  const Collectorhomescreen({super.key});

  @override
  ConsumerState<Collectorhomescreen> createState() =>
      _CollectorhomescreenState();
}

class _CollectorhomescreenState extends ConsumerState<Collectorhomescreen> {
  // Define all the screens that will be managed by the IndexedStack
  final List<Widget> _screens = const [
    Collectordashboard(), // Index 0
    Assignedmember(), // Index 1
    Addcollection(), // Index 3
    Pendingmembers(), // Index 2
    TodayCollectionsScreen(), // Index 4
    ReportsScreen(), // Index 5
    CollectorprofileScreen(), // Index 6
    AllCollectionsScreen(), // Index 7
  ];

  int getGNavIndex(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 7:
        return 4; // History
      case 5:
        return 5; // Reports
      default:
        return 0;
    }
  }

  void _onGNavTapped(int index) {
    switch (index) {
      case 0:
        _goTo(0);
        break;
      case 1:
        _goTo(1);
        break;
      case 2:
        _goTo(2);
        break;
      case 3:
        _goTo(3);
        break;
      case 4:
        ref.read(paymentHistoryMemberIdProvider.notifier).setId(0);
        _goTo(7);
        break;
      case 5:
        _goTo(5);
        break;
    }
  }

  void _goTo(int index) {
    ref.read(collectorScreenIndexProvider.notifier).goTo(index);
  }

  @override
  Widget build(BuildContext context) {
    // Read the current index from the provider
    int currentIndex = ref.watch(collectorScreenIndexProvider);

    // Default to 0 if it was -1 (the old menu state)
    if (currentIndex == -1) {
      Future.microtask(() => _goTo(0));
      currentIndex = 0;
    }

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goTo(0);
      },
      child: Scaffold(
        backgroundColor: primaryColor,
        body: IndexedStack(index: currentIndex, children: _screens),
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: SafeArea(
            child: GNav(
              gap: 4,
              backgroundColor: Colors.white,
              color: Colors.grey[400]!,
              activeColor: primaryColor,
              tabBackgroundColor: primaryColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              selectedIndex: getGNavIndex(currentIndex),
              onTabChange: _onGNavTapped,
              tabs: const [
                GButton(icon: Icons.dashboard_rounded, text: 'Overview'),
                GButton(icon: Icons.people_rounded, text: 'Members'),
                GButton(
                  icon: Icons.add_circle_outline_rounded,
                  text: 'Collect',
                ),
                GButton(icon: Icons.pending_actions_rounded, text: 'Pending'),
                GButton(icon: Icons.history_rounded, text: 'History'),
                GButton(icon: Icons.bar_chart_rounded, text: 'Reports'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
