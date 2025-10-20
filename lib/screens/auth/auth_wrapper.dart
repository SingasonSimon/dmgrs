import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
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
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      print('AuthWrapper: Checking authentication state...');
      final user = await AuthService.getCurrentUserModel();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });

        print(
          'AuthWrapper: Authentication check complete - User: ${user?.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('AuthWrapper: Authentication check error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      'AuthWrapper: Building - isLoading: $_isLoading, user: ${_currentUser?.name}',
    );

    // Show loading screen while checking authentication
    if (_isLoading) {
      print('AuthWrapper: Showing loading screen');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show appropriate screen based on authentication status
    if (_currentUser != null) {
      print('AuthWrapper: User is authenticated');
      print('AuthWrapper: User role: ${_currentUser!.role}');
      print(
        'AuthWrapper: Is admin: ${_currentUser!.role == AppConstants.adminRole}',
      );

      // User is authenticated, show appropriate home screen based on role
      if (_currentUser!.role == AppConstants.adminRole) {
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
  }
}
