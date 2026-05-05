import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/screens/groupadmin/auction/auctiongroupdetails.dart';
import 'package:kuri_app/screens/groupadmin/cash_collector/cashcollectorlist.dart';
import 'package:kuri_app/screens/groupadmin/cash_collector/createcashcollectorscreen.dart';
import 'package:kuri_app/screens/groupadmin/collection/addcollection.dart';
import 'package:kuri_app/screens/groupadmin/collection/collectionlist.dart';
import 'package:kuri_app/screens/groupadmin/collection/pending_payments.dart';
import 'package:kuri_app/screens/groupadmin/groups/groupcreate.dart';
import 'package:kuri_app/screens/groupadmin/settings_screen.dart';
import 'package:kuri_app/screens/groupadmin/member/createmember.dart';
import 'package:kuri_app/screens/groupadmin/member/memberlistscreen.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/utilities/gap_func.dart';
import 'package:kuri_app/screens/groupadmin/dashboardscreen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/models/groupadmin/notification_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotifications();
    });
  }

  void _checkNotifications() async {
    final shown = ref.read(notificationShownProvider);
    if (!shown) {
      ref.read(notificationShownProvider.notifier).state = true;
      try {
        final response = await ref.read(notificationsProvider.future);
        if (response.notifications.isNotEmpty) {
          final notification = response.notifications.first;
          _showNotificationPopUp(notification);
        }
      } catch (e) {
        debugPrint('Error fetching notifications: $e');
      }
    }
  }

  void _showNotificationPopUp(NotificationModel notification) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _NotificationPopUp(
        title: notification.title,
        message: notification.message,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showGroupOptions(BuildContext context) {
    _showBottomSheet(context, [
      _BottomSheetOption(
        title: "Group List",
        icon: Icons.list_alt_rounded,
        color: Colors.purple,
        onTap: () {
          Navigator.pop(context); // Close bottom sheet
          ref
              .read(groupScreenIndexProvider.notifier)
              .goTo(1); // Assuming 1 is TotalGroupScreen
        },
      ),
      _BottomSheetOption(
        title: "Create Group",
        icon: Icons.add_circle_outline_rounded,
        color: Colors.green,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => GroupcreateScreen()));
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CashCollectorListScreen()),
          );
        },
      ),
      _BottomSheetOption(
        title: "Add Cash Collector",
        icon: Icons.person_add_rounded,
        color: Colors.blueGrey,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Createcashcollectorscreen(),
            ),
          );
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddCollectionScreen()),
          );
        },
      ),
      _BottomSheetOption(
        title: "Collection History",
        icon: Icons.history_rounded,
        color: Colors.amber,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CollectionListScreen()),
          );
        },
      ),
      _BottomSheetOption(
        title: "Pending Approvals",
        icon: Icons.pending_actions_rounded,
        color: Colors.green,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PendingPaymentsScreen(),
            ),
          );
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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => AuctionListScreen()));
        },
      ),
    ]);
  }

  void _handleNotificationTap() {
    final asyncData = ref.read(notificationsProvider);
    final isCleared = ref.read(notificationClearedProvider);
    if (!isCleared &&
        asyncData.hasValue &&
        asyncData.value!.notifications.isNotEmpty) {
      _showNotificationDropdown(context, asyncData.value!.notifications.first);
    } else {
      _showNotificationDropdown(context, null);
    }
  }

  void _showNotificationDropdown(
    BuildContext context,
    NotificationModel? notification,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder:
          (
            BuildContext buildContext,
            Animation animation,
            Animation secondaryAnimation,
          ) {
            return SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, right: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isCleared = ref.watch(
                          notificationClearedProvider,
                        );
                        final hasNotification =
                            !isCleared && notification != null;

                        return Container(
                          width: 320,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Notifications',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A1D1E),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ref
                                                .read(
                                                  notificationClearedProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true;
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Clear All',
                                            style: GoogleFonts.inter(
                                              color: Colors.red,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: Colors.grey[200]),

                              // Notification Item
                              if (hasNotification)
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PendingPaymentsScreen(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.15,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.monetization_on_outlined,
                                              color: Colors.green,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: RichText(
                                                      text: TextSpan(
                                                        style:
                                                            GoogleFonts.inter(
                                                              color:
                                                                  const Color(
                                                                    0xFF1A1D1E,
                                                                  ),
                                                              fontSize: 14,
                                                              height: 1.4,
                                                            ),
                                                        children: [
                                                          TextSpan(
                                                            text:
                                                                '${notification.count ?? 1} Cash Handover ',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const TextSpan(
                                                            text:
                                                                'pending your approval.',
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      ref
                                                              .read(
                                                                notificationClearedProvider
                                                                    .notifier,
                                                              )
                                                              .state =
                                                          true;
                                                    },
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Amount: ₹${notification.amount?.toStringAsFixed(2) ?? '0.00'}',
                                                style: GoogleFonts.inter(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Just now',
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (hasNotification)
                                Divider(height: 1, color: Colors.grey[200]),

                              if (!hasNotification)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 30,
                                  ),
                                  child: Text(
                                    'No new notifications',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                              if (!hasNotification)
                                Divider(height: 1, color: Colors.grey[200]),

                              // Footer
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PendingPaymentsScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'View All History',
                                    style: GoogleFonts.inter(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
    );
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
                    onTap: _handleNotificationTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Color(0xFF2B3A4A),
                            size: 22,
                          ),
                        ),
                        ref
                            .watch(notificationsProvider)
                            .maybeWhen(
                              data: (data) {
                                final isCleared = ref.watch(
                                  notificationClearedProvider,
                                );
                                if (!isCleared &&
                                    data.notifications.isNotEmpty) {
                                  final title = data.notifications.first.title;
                                  final countStr =
                                      RegExp(
                                        r'\d+',
                                      ).firstMatch(title)?.group(0) ??
                                      '1';
                                  return Positioned(
                                    top: -5,
                                    right: -5,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        countStr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),
                      ],
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

class _NotificationPopUp extends StatelessWidget {
  final String title;
  final String message;

  const _NotificationPopUp({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2B3A4A), Color(0xFF3E4F5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          message,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PendingPaymentsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2B3A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Review and Approve',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
