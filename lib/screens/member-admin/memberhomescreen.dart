import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:kuri_app/screens/member-admin/memberdashboardscreen.dart';
import 'package:kuri_app/screens/member-admin/member_payment_history.dart';
import 'package:kuri_app/screens/member-admin/member_auctions.dart';
import 'package:kuri_app/screens/member-admin/member_profile.dart';
import 'package:kuri_app/utilities/colors.dart';

class Memberhomescreen extends StatefulWidget {
  final int initialIndex;
  const Memberhomescreen({super.key, this.initialIndex = 0});

  @override
  State<Memberhomescreen> createState() => _MemberhomescreenState();
}

class _MemberhomescreenState extends State<Memberhomescreen> {
  late int _currentIndex;
  final PageStorageBucket _bucket = PageStorageBucket();

  final List<Widget> _screens = const [
    MemberDashboardScreen(key: PageStorageKey('Dashboard')),
    MemberPaymentHistoryScreen(key: PageStorageKey('History')),
    MemberAuctionsScreen(key: PageStorageKey('Auctions')),
    MemberProfileScreen(key: PageStorageKey('Profile')),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: bgGrey,

        body: PageStorage(
          bucket: _bucket,
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),

        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              bottom: 15,
              top: 8,
            ),
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: glassWhite,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color:
                          primaryColor, // The thin yellow border from the screenshot
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: yellowColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    child: GNav(
                      selectedIndex: _currentIndex,
                      onTabChange: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      haptic: true,
                      gap: 8,
                      activeColor: whiteColor,
                      color: primaryColor, // Inactive icon color
                      tabBackgroundColor:
                          primaryColor, // Active pill background
                      style: GnavStyle.google,
                      iconSize: 26,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      duration: const Duration(milliseconds: 300),
                      tabBorderRadius: 30,
                      tabs: const [
                        GButton(
                          icon: Icons.dashboard_outlined,
                          text: 'Dashboard',
                        ),
                        GButton(
                          icon: Icons.receipt_long_outlined,
                          text: 'History',
                        ),
                        GButton(icon: Icons.gavel_outlined, text: 'Auctions'),
                        GButton(
                          icon: Icons.person_outline_rounded,
                          text: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
