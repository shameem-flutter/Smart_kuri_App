import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/screens/groupadmin/profilescreen.dart';
import '../../providers/auth_provider_riverpod.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B3A4A),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(
            color: Colors.grey[600],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2B3A4A)),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings Header
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B3A4A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account and preferences',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
              ),

              const SizedBox(height: 32),

              // Minimal User Info Card
              // Container(
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(24),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withValues(alpha: 0.03),
              //         blurRadius: 20,
              //         offset: const Offset(0, 8),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     children: [
              //       Container(
              //         height: 56,
              //         width: 56,
              //         decoration: BoxDecoration(
              //           color: const Color(0xFF2962FF).withValues(alpha: 0.1),
              //           shape: BoxShape.circle,
              //         ),
              //         child: const Center(
              //           child: Icon(
              //             Icons.person_outline_rounded,
              //             color: Color(0xFF2962FF),
              //             size: 28,
              //           ),
              //         ),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'Group Admin',
              //               style: GoogleFonts.poppins(
              //                 fontSize: 18,
              //                 fontWeight: FontWeight.w600,
              //                 color: const Color(0xFF2B3A4A),
              //               ),
              //             ),
              //             const SizedBox(height: 2),
              //             Text(
              //               'admin@kuri.app',
              //               style: GoogleFonts.inter(
              //                 fontSize: 13,
              //                 color: Colors.grey[500],
              //                 fontWeight: FontWeight.w500,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       // Minimal Admin Badge
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 10,
              //           vertical: 5,
              //         ),
              //         decoration: BoxDecoration(
              //           color: Colors.green.withValues(alpha: 0.1),
              //           borderRadius: BorderRadius.circular(10),
              //         ),
              //         child: Text(
              //           'ADMIN',
              //           style: GoogleFonts.inter(
              //             color: Colors.green[700],
              //             fontSize: 10,
              //             fontWeight: FontWeight.w700,
              //             letterSpacing: 0.5,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 32),

              // General Section
              Text(
                'GENERAL',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: 'Manage your profile information',
                iconColor: const Color(0xFF2962FF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Profilescreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Configure notification preferences',
                iconColor: Colors.orange,
                onTap: () {},
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'Security',
                subtitle: 'Password and security settings',
                iconColor: Colors.green,
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // Account Section
              Text(
                'ACCOUNT',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                iconColor: Colors.redAccent,
                onTap: () => _handleLogout(context, ref),
                hideArrow: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final bool hideArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.hideArrow = false,
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
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Leading Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B3A4A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Arrow (Conditional)
                if (!hideArrow)
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
