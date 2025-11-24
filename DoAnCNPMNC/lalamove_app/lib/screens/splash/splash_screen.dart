import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../customer/home/home_screen.dart' as customer_home;
import '../intake/home/home_screen.dart' as intake_home;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🚀 Initializing app...');
    
    // Load saved auth data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadAuthData();
    
    // Wait for splash screen animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Navigate based on authentication and role
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final user = authProvider.user!;
      print('✅ User authenticated: ${user.email} (${user.role})');
      
      // Initialize push notifications
      try {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.initializeNotifications();
        print('✅ Push notifications initialized');
      } catch (e) {
        print('⚠️ Failed to initialize notifications: $e');
      }
      
      // Navigate based on role
      _navigateToRoleScreen(user.role);
    } else {
      print('❌ No authenticated user, navigating to login...');
      _navigateToLogin();
    }
  }

  void _navigateToRoleScreen(String role) {
    Widget targetScreen;
    
    switch (role) {
      case UserRole.customer:
        print('📱 Navigating to Customer Home...');
        targetScreen = const customer_home.HomeScreen();
        break;
      
      case UserRole.intakeStaff:
        print('📦 Navigating to Intake Home...');
        targetScreen = const intake_home.HomeScreen();
        break;
      
      case UserRole.driver:
        print('🚗 Navigating to Driver Home...');
        // TODO: Create driver home screen
        targetScreen = const LoginScreen(); // Temporary
        break;
      
      case UserRole.admin:
        print('👑 Navigating to Admin Dashboard...');
        // TODO: Create admin dashboard
        targetScreen = const LoginScreen(); // Temporary
        break;
      
      default:
        print('⚠️ Unknown role: $role, navigating to login...');
        targetScreen = const LoginScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // App name
            const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                letterSpacing: 1.5,
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Tagline
            const Text(
              'Giao hàng nhanh - An toàn - Tiện lợi',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Loading indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.white,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
