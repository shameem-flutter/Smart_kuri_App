import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utilities/colors.dart';
import '../../../utilities/validators.dart';
import '../../../providers/auth_provider_riverpod.dart';
// import '../../../providers/group_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
// import 'package:kuri_app/models/auth/plan_model.dart';
import 'verify_otp_screen.dart';

/// Register Screen — separate from LoginScreen
class RegisterScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToLogin;

  const RegisterScreen({super.key, this.onNavigateToLogin});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(authProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(authProvider.notifier).clearMessages();
    } else if (authState.successMessage != null) {
      final successMsg = authState.successMessage!;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      ref.read(authProvider.notifier).clearMessages();

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const VerifyOtpScreen()));

      Future.delayed(const Duration(milliseconds: 300), () {
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: darkNavy,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Decorations
          Positioned(
            top: -60,
            right: -60,
            child: _Circle(
              color: primaryColor.withValues(alpha: 0.08),
              size: 220,
            ),
          ),
          Positioned(
            bottom: 200,
            left: -40,
            child: _Circle(
              color: primaryColor.withValues(alpha: 0.05),
              size: 160,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + header
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed:
                        widget.onNavigateToLogin ??
                        () => Navigator.of(context).pop(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create your\naccount',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign up to enjoy the best managing experience',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Basic Info ──────────────────────────
                            _sectionLabel('Basic Information'),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _nameController,
                              label: '',
                              hint: 'Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _emailController,
                              label: '',
                              hint: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _phoneController,
                              label: '',
                              hint: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Required' : null,
                            ),

                            const SizedBox(height: 20),

                            // ── Password ────────────────────────────
                            _sectionLabel('Set Password'),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _passwordController,
                              label: '',
                              hint: 'Password',
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: '',
                              hint: 'Confirm Password',
                              obscureText: _obscureConfirm,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Required';
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            // ── Subscription Plan ────────────────────

                            // Validation hint if no plan selected and tried to submit
                            const SizedBox(height: 24),

                            CustomButton(
                              text: 'Create Account',
                              onPressed: _handleRegister,
                              backgroundColor: primaryColor,
                              icon: Icons.person_add_alt_1_rounded,
                              isLoading: authState.isLoading,
                            ),

                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      widget.onNavigateToLogin ??
                                      () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2B3A4A),
      ),
    );
  }

  IconData _planIcon(int index) {
    const icons = [
      Icons.rocket_launch_outlined,
      Icons.workspace_premium_outlined,
      Icons.diamond_outlined,
      Icons.star_outline_rounded,
    ];
    return icons[index % icons.length];
  }
}

class _Circle extends StatelessWidget {
  final Color color;
  final double size;
  const _Circle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
