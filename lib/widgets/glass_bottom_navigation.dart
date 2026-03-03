import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:kuri_app/utilities/colors.dart';

class GlassBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;
  final List<GButton> tabs;

  const GlassBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
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
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                child: GNav(
                  selectedIndex: selectedIndex,
                  onTabChange: onTabChange,
                  haptic: true,
                  gap: 5,
                  activeColor: whiteColor,
                  color: primaryColor.withValues(alpha: 0.9),
                  tabBackgroundColor: primaryColor,
                  style: GnavStyle.google,
                  iconSize: 26,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  duration: const Duration(milliseconds: 400),
                  tabBorderRadius: 30,
                  tabs: tabs,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
