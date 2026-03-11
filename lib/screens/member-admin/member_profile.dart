import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kuri_app/models/member/member_profile_model.dart';
import 'package:kuri_app/providers/auth_provider_riverpod.dart';
import 'package:kuri_app/providers/group_provider.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:kuri_app/widgets/custom_error_widget.dart';

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(memberProfileProvider);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: bgGrey,
      body: profileAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (e, _) => CustomErrorWidget(
          error: e.toString().replaceAll('Exception: ', ''),
          onRetryFuture: () async {
            ref.invalidate(memberProfileProvider);
            try {
              await ref.read(memberProfileProvider.future);
            } catch (_) {}
          },
        ),
        data: (data) => RefreshIndicator(
          color: primaryColor,
          onRefresh: () async => ref.invalidate(memberProfileProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(context, ref, data),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoCard(context, data),
                    const SizedBox(height: 16),
                    _buildPersonalCard(context, data),
                    const SizedBox(height: 16),
                    _buildGroupCard(context, data),
                    const SizedBox(height: 32),
                    _LogoutButton(ref: ref),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    MemberProfileResponse data,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    // Back button
                    Builder(
                      builder: (ctx) => _NavCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(ctx).maybePop(),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        color: blackColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    _NavCircleButton(
                      icon: Icons.logout,
                      iconColor: redColor,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // ── Avatar ───────────────────────────────────
                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      // BoxShadow(
                      //   color: primaryColor.withValues(alpha: 0.35),
                      //   blurRadius: 10,
                      //   spreadRadius: 1,
                      //   offset: const Offset(0, 8),
                      // ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      data.name.isNotEmpty ? data.name[0].toUpperCase() : 'M',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.name,
                  style: GoogleFonts.outfit(
                    color: blackColor,
                    fontSize: 24,
                    // fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: blackColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.isActive
                            ? Icons.verified_rounded
                            : Icons.cancel_rounded,
                        color: data.isActive
                            ? Color(0xFF4CAF50)
                            : Colors.redAccent[100],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.isActive ? 'ACTIVE MEMBER' : 'INACTIVE',
                        style: GoogleFonts.inter(
                          color: data.isActive
                              ? Color(0xFF4CAF50)
                              : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, MemberProfileResponse data) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Account Information'),
          const SizedBox(height: 16),
          // _InfoRow(icon: Icons.badge_rounded, label: 'Member ID', value: '#${data.id}'),
          // const _Divider(),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: data.phone,
          ),
          const _Divider(),
          _InfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: data.email.isNotEmpty ? data.email : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard(BuildContext context, MemberProfileResponse data) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Personal Details'),
          const SizedBox(height: 16),
          if (data.address.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: data.address,
            ),
            const _Divider(),
          ],
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Join Date',
            value: data.formattedJoinDate,
          ),
          if (data.aadhaarMasked.isNotEmpty) ...[
            const _Divider(),
            _InfoRow(
              icon: Icons.fingerprint_rounded,
              label: 'Aadhaar',
              value: data.aadhaarMasked,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, MemberProfileResponse data) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Kuri Group'),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.layers_rounded,
            label: 'Group Name',
            value: data.groupName,
          ),

          // _InfoRow(
          //   icon: Icons.numbers_rounded,
          //   label: 'Group ID',
          //   value: '#${data.groupId}',
          // ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────
// Logout Button
// ─────────────────────────────────────────────────────────────
Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
  bool isLoggingOut = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
        ),
        title: Text(
          'Log Out?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoggingOut
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoggingOut
                      ? null
                      : () async {
                           setDialogState(() => isLoggingOut = true);
                           // ref.listen in main.dart handles popping all
                           // routes and transitioning to LoginScreen
                           await ref.read(authProvider.notifier).logout();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A5F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoggingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Log Out',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref2) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5A5F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
        label: Text(
          'Log Out',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xFFF1F4F9)),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _NavCircleButton({this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          // Dark semi-transparent fill — same as reference
          color: iconColor ?? Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(icon, color: whiteColor, size: 18),
      ),
    );
  }
}
