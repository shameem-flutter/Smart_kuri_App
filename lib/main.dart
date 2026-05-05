import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'utilities/api_config.dart';
import 'screens/splash_screen.dart';
import 'screens/groupadmin/auth/login_screen.dart';
import 'screens/groupadmin/auth/register_screen.dart';
import 'screens/groupadmin/auth/password_reset_screen.dart';
import 'screens/groupadmin/auth/first_login_password_screen.dart';
import 'screens/collector-admin/collectorhomescreen.dart';
import 'screens/member-admin/memberhomescreen.dart';
import 'screens/groupadmin/groups/onetimegroupcreation.dart';
import 'screens/groupadmin/group_admin_main_screen.dart';
import 'providers/auth_provider_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  // GoogleFonts.config.allowRuntimeFetching = false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for logout: when auth goes from authenticated -> unauthenticated,
    // pop all pushed routes (Settings, Profile, etc.) to reveal the home route.
    // Deferred to post-frame to avoid popping mid-rebuild.
    // Listen for state changes: when auth is lost OR setup is required,
    // pop all pushed routes to ensure the correct root screen is shown.
    ref.listen<AuthState>(authProvider, (prev, next) {
      final wasAuth = prev?.isAuthenticated ?? false;
      final isAuth = next.isAuthenticated;
      final wasSetupNeeded = prev?.needsOnetimeSetup ?? false;
      final isSetupNeeded = next.needsOnetimeSetup;

      if ((wasAuth && !isAuth) ||
          (!wasSetupNeeded && isSetupNeeded) ||
          (wasSetupNeeded && !isSetupNeeded)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_navigatorKey.currentState != null) {
            _navigatorKey.currentState!.popUntil((route) => route.isFirst);
          }
        });
      }
    });

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Kuri App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildHome(authState),
      ),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (!authState.isInitialized) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    if (authState.isAuthenticated) {
      if (authState.isFirstLogin) {
        return const FirstLoginChangePasswordScreen(
          key: ValueKey('first_login'),
        );
      }

      if (authState.needsOnetimeSetup &&
          authState.role != 'member' &&
          authState.role != 'collector') {
        return const Onetimegroupcreation(key: ValueKey('onetime_setup'));
      }

      if (authState.role == 'member') {
        return const Memberhomescreen(key: ValueKey('member_home'));
      } else if (authState.role == 'collector') {
        return const Collectorhomescreen(key: ValueKey('collector_home'));
      } else {
        return const GroupAdminMainScreen(key: ValueKey('admin_home'));
      }
    }

    // Unauthenticated — show auth views via IndexedStack (no route push = no blink)
    return _buildAuthViews();
  }

  Widget _buildAuthViews() {
    final currentView = ref.watch(authViewProvider);

    return PopScope(
      // Allow pop (app exit) only when on the login screen
      canPop: currentView == AuthViewMode.login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Back pressed on register/forgotPassword → go back to login
          ref.read(authViewProvider.notifier).switchTo(AuthViewMode.login);
        }
      },
      child: IndexedStack(
        key: const ValueKey('auth'),
        index: currentView.index,
        children: [
          LoginScreen(
            onNavigateToRegister: () => ref
                .read(authViewProvider.notifier)
                .switchTo(AuthViewMode.register),
            onNavigateToForgotPassword: () => ref
                .read(authViewProvider.notifier)
                .switchTo(AuthViewMode.forgotPassword),
          ),
          RegisterScreen(
            onNavigateToLogin: () => ref
                .read(authViewProvider.notifier)
                .switchTo(AuthViewMode.login),
          ),
          PasswordResetScreen(
            onNavigateBack: () => ref
                .read(authViewProvider.notifier)
                .switchTo(AuthViewMode.login),
          ),
        ],
      ),
    );
  }
}
