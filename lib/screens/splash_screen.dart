import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuri_app/providers/auth_provider_riverpod.dart';
import 'package:kuri_app/screens/member-admin/memberhomescreen.dart';
import 'package:kuri_app/screens/groupadmin/group_admin_main_screen.dart';
import 'package:kuri_app/screens/groupadmin/auth/login_screen.dart';
import 'package:kuri_app/screens/collector-admin/collectorhomescreen.dart';
import 'package:kuri_app/utilities/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Text Animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Start animations sequentially
    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });

    // Handle navigation after delay + check
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // Minimum splash duration to let the animation play
    final minimumDelay = Future.delayed(const Duration(milliseconds: 2800));

    // Auth initialization check
    final authInitialization = ref.read(authProvider.notifier).initialize();

    await Future.wait([minimumDelay, authInitialization]);

    if (!mounted) return;

    final authState = ref.read(authProvider);

    Widget nextScreen;
    if (authState.isAuthenticated) {
      if (authState.role == 'member') {
        nextScreen = const Memberhomescreen();
      } else if (authState.role == 'collector') {
        nextScreen = const Collectorhomescreen();
      } else {
        nextScreen = const GroupAdminMainScreen();
      }
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) =>
            FadeTransition(opacity: animation, child: nextScreen),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_logoController, _textController]),
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with fade + scale animation
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        // width: 132, // 100 (image) + 16*2 (padding)
                        // height: 132, // explicit size ensures a perfect circle
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          "assets/images/smartt.png",
                          height: 80,
                          width: 80,
                          fit: BoxFit
                              .cover, // 'contain' prevents cropping your logo
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.security,
                                size: 80,
                                color: Colors.blueAccent,
                              ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Text content with fade + slide up
                  Opacity(
                    opacity: _textFade.value,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            "Smart Kuri",
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: blackColor,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Your Digital Safe",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: blackColor,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80), // Bottom padding
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
