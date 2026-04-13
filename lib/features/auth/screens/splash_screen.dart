import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _authTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Check auth state after animation
    _authTimer = Timer(const Duration(seconds: 2), () {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    if (!mounted) {
      return;
    }

    final user = ref.read(currentUserProvider);

    if (user == null) {
      // Not logged in, show onboarding
      context.go('/onboarding');
    } else {
      // Logged in, fetch role and route accordingly
      _routeByRole(user.uid);
    }
  }

  Future<void> _routeByRole(String uid) async {
    try {
      final userDoc = await ref.read(userDataProvider(uid).future);

      if (userDoc == null) {
        // User document doesn't exist, go to role selection
        if (mounted) {
          context.go('/role-selection');
        }
        return;
      }

      if (mounted) {
        switch (userDoc.role) {
          case UserRoles.customer:
            context.goToCustomerHome();
            break;
          case UserRoles.provider:
            context.goToProviderDashboard();
            break;
          case UserRoles.admin:
            context.goToAdminDashboard();
            break;
          default:
            context.go('/role-selection');
        }
      }
    } catch (e) {
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.home_repair_service,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Name
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    const Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
