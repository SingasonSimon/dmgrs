import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../member/member_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../shared/welcome_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure authentication state is properly initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print(
          'AuthWrapper: Rebuilding - isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}, error: ${authProvider.error}',
        );
        print('AuthWrapper: Current user: ${authProvider.currentUser?.name}');
        print(
          'AuthWrapper: Current user role: ${authProvider.currentUser?.role}',
        );

        // Show loading screen while checking authentication
        if (authProvider.isLoading) {
          print('AuthWrapper: Showing loading screen');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show error if there's an authentication error
        if (authProvider.error != null) {
          print('AuthWrapper: Showing error screen - ${authProvider.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      authProvider.clearError();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show appropriate screen based on authentication status
        if (authProvider.isAuthenticated && authProvider.currentUser != null) {
          print('AuthWrapper: User is authenticated');
          print('AuthWrapper: User role: ${authProvider.currentUser!.role}');
          print('AuthWrapper: Is admin: ${authProvider.isAdmin}');

          // User is authenticated, show appropriate home screen based on role
          if (authProvider.isAdmin) {
            print('AuthWrapper: Showing admin home screen');
            return const AdminHomeScreen();
          } else {
            print('AuthWrapper: Showing member home screen');
            return const MemberHomeScreen();
          }
        } else {
          print(
            'AuthWrapper: User is not authenticated, showing welcome screen',
          );
          // User is not authenticated, show welcome screen
          return const WelcomeScreen();
        }
      },
    );
  }
}
