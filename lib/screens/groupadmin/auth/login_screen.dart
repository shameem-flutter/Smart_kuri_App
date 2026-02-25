import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kuri_app/screens/collector-admin/collectorhomescreen.dart';
import 'package:kuri_app/utilities/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utilities/validators.dart';
import '../../../providers/auth_provider_riverpod.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../home_screen.dart';
import '../../member-admin/memberdashboardscreen.dart';
import 'password_reset_screen.dart';
import 'verify_otp_screen.dart';

/// Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authProvider.notifier);
    FocusScope.of(context).unfocus();

    if (_isLogin) {
      await authNotifier.login(
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      int planId = int.tryParse(_licenseController.text.trim()) ?? 2;

      await authNotifier.register(
        groupName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        planId: planId,
      );
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.successMessage!),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(authProvider.notifier).clearMessages();

      if (!_isLogin) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const VerifyOtpScreen()));
        return;
      }
    }

    if (authState.isAuthenticated) {
      if (authState.role == 'member') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MemberDashboardScreen()),
        );
      } else if (authState.role == "collector") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Collectorhomescreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          // Background Decorations
          Positioned(
            top: -50,
            left: -50,
            child: _CircleDecorator(
              color: primaryColor.withValues(alpha: 0.1),
              size: 200,
            ),
          ),
          Positioned(
            top: 100,
            right: -30,
            child: _CircleDecorator(
              color: primaryColor.withValues(alpha: 0.05),
              size: 150,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 10),
                  child: BackButton(color: Colors.white),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLogin
                            ? 'Go ahead and set up\nyour account'
                            : 'Create your\naccount',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sign ${_isLogin ? 'in' : 'up'} to enjoy the best managing experience',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildToggle(),
                            ),
                            const SizedBox(height: 20),

                            // Form Fields based on state
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isLogin
                                  ? _buildLoginForm()
                                  : _buildRegisterForm(),
                            ),

                            const SizedBox(height: 20),

                            // Auth Button
                            CustomButton(
                              text: _isLogin ? 'Login' : 'Register',
                              onPressed: _handleAuth,
                              backgroundColor: primaryColor,
                              icon: _isLogin ? Icons.login : Icons.person_add,
                              isLoading: authState.isLoading,
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

  Widget _buildToggle() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isLogin = true),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isLogin ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isLogin = false),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_isLogin ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        CustomTextField(
          controller: _emailController,
          label: '',
          hint: 'E-mail ID',
          prefixIcon: const Icon(Icons.email_outlined),
          validator: Validators.validateIdentifier,
        ),
        const SizedBox(height: 16),
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
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        CustomTextField(
          controller: _nameController,
          label: '',
          hint: 'Group Name',
          prefixIcon: const Icon(Icons.person_outline),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _emailController,
          label: '',
          hint: 'Email-ID',
          prefixIcon: const Icon(Icons.email_outlined),
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _phoneController,
          label: '',
          hint: 'Phone No.',
          prefixIcon: const Icon(Icons.phone_outlined),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _passwordController,
          label: '',
          hint: 'Password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
          validator: Validators.validatePassword,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _confirmPasswordController,
          label: "",
          hint: "Confirm Password",
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _licenseController,
          label: '',
          hint: 'Plan-no (Default: 2)',
          prefixIcon: const Icon(Icons.credit_card_outlined),
        ),
      ],
    );
  }
}

class _CircleDecorator extends StatelessWidget {
  final Color color;
  final double size;
  const _CircleDecorator({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
