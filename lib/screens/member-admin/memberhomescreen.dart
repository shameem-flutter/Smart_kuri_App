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
  bool hasNavigatedAway = false;

  final PageStorageBucket _bucket = PageStorageBucket();

  // Defined your primary color here to make the GNav properties much cleaner

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

  Future<bool> _handleBackButton() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        hasNavigatedAway = true;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _handleBackButton();

        if (!shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
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
              top: 08,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 02, sigmaY: 02),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        whiteColor.withValues(alpha: 0.7),
                        whiteColor.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: whiteColor.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: whiteColor.withValues(alpha: 0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
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
                      gap: 5,

                      activeColor: whiteColor,
                      color: primaryColor.withValues(alpha: 0.90),
                      tabBackgroundColor: primaryColor,
                      style: GnavStyle.google,
                      iconSize: 26,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      duration: const Duration(milliseconds: 400),
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
