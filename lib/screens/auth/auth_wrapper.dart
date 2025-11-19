import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../member/member_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../shared/welcome_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Initial auth check
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    try {
      print('AuthWrapper: Checking initial authentication state...');
      final user = await AuthService.getCurrentUserModel();
      print('AuthWrapper: Initial auth check complete - User: ${user?.name}');
    } catch (e) {
      print('AuthWrapper: Initial auth check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initial check
    if (_isInitialLoading) {
      print('AuthWrapper: Showing initial loading screen');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Listen to AuthProvider for auth state changes
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.currentUser;
        
        print(
          'AuthWrapper: Building - user: ${currentUser?.name}, isAuthenticated: ${authProvider.isAuthenticated}',
        );

        // Show loading if auth provider is loading
        if (authProvider.isLoading) {
          print('AuthWrapper: AuthProvider is loading');
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Show appropriate screen based on authentication status
        if (currentUser != null && authProvider.isAuthenticated) {
          print('AuthWrapper: User is authenticated - ${currentUser.name} (${currentUser.role})');

          // User is authenticated, show appropriate home screen based on role
          if (currentUser.role == AppConstants.adminRole) {
            print('AuthWrapper: Showing admin home screen');
            return const AdminHomeScreen();
          } else {
            print('AuthWrapper: Showing member home screen');
            return const MemberHomeScreen();
          }
        } else {
          print('AuthWrapper: User is not authenticated, showing welcome screen');
          // User is not authenticated, show welcome screen
          return const WelcomeScreen();
        }
      },
    );
  }
}
