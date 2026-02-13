import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/screens/groupadmin/groupdetails.dart';
import 'package:kuri_app/screens/groupadmin/settings_screen.dart';
import 'package:kuri_app/screens/member/createmember.dart';
import 'package:kuri_app/screens/member/memberlistscreen.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/utilities/gap_func.dart';
import 'package:kuri_app/screens/groupadmin/dashboardscreen.dart';
import 'package:kuri_app/widgets/ip_config_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showGroupOptions(BuildContext context) {
    _showBottomSheet(context, [
      _BottomSheetOption(
        title: "Group List",
        icon: Icons.list_alt_rounded,
        color: Colors.purple,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GroupDetailsScreen()),
          );
        },
      ),
      _BottomSheetOption(
        title: "Create Group",
        icon: Icons.add_circle_outline_rounded,
        color: Colors.green,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Create Group
        },
      ),
      _BottomSheetOption(
        title: "Reports",
        icon: Icons.bar_chart_rounded,
        color: Colors.blue,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Reports
        },
      ),
    ]);
  }

  void _showMemberOptions(BuildContext context) {
    _showBottomSheet(context, [
      _BottomSheetOption(
        title: "Member List",
        icon: Icons.people_outline_rounded,
        color: Colors.orange,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => MemberListScreen()));
        },
      ),
      _BottomSheetOption(
        title: "Create Member",
        icon: Icons.person_add_alt_1_rounded,
        color: Colors.green,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => CreateMemberScreen()));
        },
      ),
      _BottomSheetOption(
        title: "Cash Collector List",
        icon: Icons.supervisor_account_rounded,
        color: Colors.teal,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Cash Collector List
        },
      ),
      _BottomSheetOption(
        title: "Add Cash Collector",
        icon: Icons.person_add_rounded,
        color: Colors.blueGrey,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Add Cash Collector
        },
      ),
      _BottomSheetOption(
        title: "Reports",
        icon: Icons.analytics_outlined,
        color: Colors.blue,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Reports
        },
      ),
    ]);
  }

  void _showCollectionOptions(BuildContext context) {
    _showBottomSheet(context, [
      _BottomSheetOption(
        title: "Add Collection",
        icon: Icons.add_card_rounded,
        color: Colors.teal,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Add Collection
        },
      ),
      _BottomSheetOption(
        title: "Collection History",
        icon: Icons.history_rounded,
        color: Colors.amber,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Collection History
        },
      ),
    ]);
  }

  void _showAuctionOptions(BuildContext context) {
    _showBottomSheet(context, [
      _BottomSheetOption(
        title: "Auction List",
        icon: Icons.gavel_rounded,
        color: Colors.redAccent,
        onTap: () {
          Navigator.pop(context);
          // Navigate to Auction List
        },
      ),
    ]);
  }

  void _showBottomSheet(
    BuildContext context,
    List<_BottomSheetOption> options,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ...options.map(
                (option) => Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: option.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(option.icon, color: option.color, size: 22),
                      ),
                      title: Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      onTap: option.onTap,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Light gray background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IpConfigDialog(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2B3A4A), // Dark color for IP button
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'IP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Color(0xFF2B3A4A),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Dashboard Title
              buildHeaderCard(),

              const SizedBox(height: 20),

              // Menu Items
              _DashboardCard(
                title: "Dashboard",
                subtitle: "details of the Group",
                icon: Icons.dashboard,
                iconColor: primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
              ),
              vertGap(08),

              _DashboardCard(
                title: 'Groups',
                subtitle: 'Manage your groups',
                icon: Icons.layers_rounded,
                iconColor: Colors.blue,
                onTap: () => _showGroupOptions(context),
              ),
              vertGap(08),
              _DashboardCard(
                title: 'Members',
                subtitle: 'View member details',
                icon: Icons.people_rounded,
                iconColor: Colors.blueAccent, // Lighter blue
                onTap: () => _showMemberOptions(context),
              ),
              vertGap(08),
              _DashboardCard(
                title: 'Collections',
                subtitle: 'Track payment history',
                icon: Icons.inventory_2_rounded,
                iconColor: Colors.teal,
                onTap: () => _showCollectionOptions(context),
              ),
              vertGap(08),
              _DashboardCard(
                title: 'Auctions',
                subtitle: 'Manage auctions',
                icon: Icons.gavel_rounded,
                iconColor: Colors.orange,
                onTap: () => _showAuctionOptions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetOption {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _BottomSheetOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                // Leading Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 20),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                // Trailing Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[300],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildHeaderCard() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Welcome to Smart Kuri',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(
            0xFF2B3A4A,
          ), // Matches your IP button/settings icon color
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Select an option to proceed',
        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
      ),
    ],
  );
}
