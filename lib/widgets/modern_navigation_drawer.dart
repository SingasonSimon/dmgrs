import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../screens/admin/admin_profile_screen.dart';

class ModernNavigationDrawer extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final Function(int)? onNavigationTap;
  final bool isAdmin;

  const ModernNavigationDrawer({
    super.key,
    this.onProfileTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.onNavigationTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileSection(context),
                      const SizedBox(height: 20),
                      _buildThemeSection(context),
                      const SizedBox(height: 20),
                      _buildMenuItems(context),
                      const Spacer(),
                      _buildLogoutButton(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.onPrimary,
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ],
              ),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Digital Merry Go Round',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  authProvider.userDisplayName.isNotEmpty
                      ? authProvider.userDisplayName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.userDisplayName.isNotEmpty
                          ? authProvider.userDisplayName
                          : 'User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: authProvider.isAdmin
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authProvider.isAdmin ? 'Admin' : 'Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProfileScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppThemeMode.values
                    .where(
                      (theme) => theme != AppThemeMode.dark,
                    ) // Exclude dark mode
                    .map((theme) {
                      final isSelected = themeProvider.currentTheme == theme;
                      return GestureDetector(
                        onTap: () => themeProvider.setTheme(theme),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getThemeColor(theme),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    if (isAdmin) {
      return Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(0);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.people,
            title: 'Members',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(1);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance,
            title: 'Loans',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(2);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.rotate_right,
            title: 'Allocations',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(3);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.analytics,
            title: 'Reports',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(4);
              }
            },
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onProfileTap?.call();
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                _showHelpDialog(context);
              }
            },
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.dashboard,
            title: 'Home',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(0);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.payments,
            title: 'Contributions',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(1);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.account_balance,
            title: 'Loans',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(2);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.rotate_right,
            title: 'Allocations',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(3);
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.calendar_today,
            title: 'Meetings',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(4); // Meetings is now at index 4
              }
            },
          ),
          const Divider(),
          _buildMenuItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                onNavigationTap?.call(5); // Profile is now at index 5
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              if (context.mounted) {
                Navigator.pop(context);
                _showHelpDialog(context);
              }
            },
          ),
        ],
      );
    }
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
        ),
        onTap: onLogoutTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getThemeColor(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.light:
        return Colors.grey.shade300;
      case AppThemeMode.dark:
        return Colors.grey.shade800;
      case AppThemeMode.blue:
        return const Color(0xFF1976D2);
      case AppThemeMode.green:
        return const Color(0xFF388E3C);
      case AppThemeMode.purple:
        return const Color(0xFF7B1FA2);
    }
  }

  void _showHelpDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Here are some resources:'),
            SizedBox(height: 16),
            Text('• Check the FAQ section in your profile'),
            Text('• Contact support through the app'),
            Text('• Review the user guide'),
            SizedBox(height: 16),
            Text('For technical issues, please contact the administrator.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
