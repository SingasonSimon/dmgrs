import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../services/image_picker_service.dart';
import '../../services/s3_service.dart';
import '../shared/welcome_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(context, user),

                  const SizedBox(height: 24),

                  // Profile Information
                  _buildProfileInfo(context, user),

                  const SizedBox(height: 24),

                  // Account Actions
                  _buildAccountActions(context),

                  const SizedBox(height: 24),

                  // App Information
                  _buildAppInfo(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: user.profileUrl != null
                      ? NetworkImage(user.profileUrl!)
                      : null,
                  child: user.profileUrl == null
                      ? Text(
                          user.initials,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 20),
                      color: Theme.of(context).colorScheme.onPrimary,
                      onPressed: () => _showImagePickerDialog(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                AppHelpers.getUserRoleDisplayName(user.role),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, user) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Profile Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          _buildInfoTile(context, 'Phone Number', user.phone, Icons.phone),
          _buildInfoTile(
            context,
            'Member Since',
            AppHelpers.formatDate(user.joinedAt),
            Icons.calendar_today,
          ),
          if (user.lastLoginAt != null)
            _buildInfoTile(
              context,
              'Last Login',
              AppHelpers.getRelativeTime(user.lastLoginAt!),
              Icons.login,
            ),
          _buildInfoTile(
            context,
            'Account Status',
            user.status.toUpperCase(),
            Icons.verified_user,
            valueColor: user.isActive ? Colors.green : Colors.red,
          ),
          if (user.consecutiveMisses > 0)
            _buildInfoTile(
              context,
              'Consecutive Misses',
              '${user.consecutiveMisses}',
              Icons.warning,
              valueColor: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        style: TextStyle(
          color: valueColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: valueColor != null ? FontWeight.w500 : null,
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Account Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Verification'),
            trailing: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return authProvider.isEmailVerified
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.warning, color: Colors.orange);
              },
            ),
            onTap: () {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              if (!authProvider.isEmailVerified) {
                _showEmailVerificationDialog(context);
              } else {
                AppHelpers.showSnackBar(context, 'Email is already verified');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSignOutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'App Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('FAQ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFAQDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: const Text('Contact Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showContactDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTermsOfServiceDialog(context),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification'),
        content: const Text(
          'Your email address is not verified. Would you like to send a verification email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final success = await authProvider.sendEmailVerification();
              if (success && context.mounted) {
                AppHelpers.showSuccessSnackBar(
                  context,
                  'Verification email sent!',
                );
              } else if (context.mounted) {
                AppHelpers.showErrorSnackBar(
                  context,
                  authProvider.error ?? 'Failed to send verification email',
                );
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();
              // Navigation will be handled by AuthWrapper listening to AuthProvider
              if (context.mounted) {
                AppHelpers.showSuccessSnackBar(
                  context,
                  'Signed out successfully',
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: const Text(
          'Choose how you want to update your profile picture:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera(context);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery(context);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    try {
      final file = await ImagePickerService.pickImageFromCamera();
      if (file != null && context.mounted) {
        await _uploadProfileImage(context, file);
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final file = await ImagePickerService.pickImageFromGallery();
      if (file != null && context.mounted) {
        await _uploadProfileImage(context, file);
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _uploadProfileImage(BuildContext context, File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Uploading image...'),
            ],
          ),
        ),
      );

      // Validate image file
      if (!ImagePickerService.isValidImageFile(imageFile)) {
        throw Exception(
          'Invalid image format. Please select JPG, PNG, or GIF.',
        );
      }

      if (!ImagePickerService.isFileSizeValid(imageFile)) {
        throw Exception(
          'Image file is too large. Please select an image under 5MB.',
        );
      }

      // Upload to S3
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final imageUrl = await S3Service.uploadProfileImage(
        imageFile: imageFile,
        userId: authProvider.userId,
      );

      // Update user profile with new image URL
      await authProvider.updateProfile(
        name: authProvider.userDisplayName,
        phone: authProvider.userPhone,
        profileUrl: imageUrl,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppHelpers.showSuccessSnackBar(
          context,
          'Profile picture updated successfully!',
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        AppHelpers.showErrorSnackBar(context, 'Failed to upload image: $e');
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Digital Merry Go Round!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Here\'s how to use the app:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Make monthly contributions through M-Pesa'),
              Text('• Request loans when you need financial assistance'),
              Text('• Track your fund allocations and cycle progress'),
              Text('• View your payment history and loan status'),
              SizedBox(height: 16),
              Text(
                'Need more help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Contact our support team at:'),
              Text('Email: singason65@gmail.com'),
              Text('Phone: +254 748 088 741'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: How do I make a contribution?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Go to Payments tab and tap "Make Payment". You\'ll receive an M-Pesa prompt.',
              ),
              SizedBox(height: 12),
              Text(
                'Q: When will I receive my allocation?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Allocations are distributed based on the cycle order. Check the Allocations tab for your position.',
              ),
              SizedBox(height: 12),
              Text(
                'Q: How do I request a loan?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Go to Loans tab and tap "Request Loan". Fill in the amount and purpose.',
              ),
              SizedBox(height: 12),
              Text(
                'Q: What if I miss a payment?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Contact the admin immediately. Late payments may incur penalties.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get in touch with our support team:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text('singason65@gmail.com'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.phone, size: 20),
                SizedBox(width: 8),
                Text('+254 748 088 741'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.chat, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                const Text('+254 743 466 295'),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(context),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.location_on, size: 20),
                SizedBox(width: 8),
                Text('Nairobi, Kenya'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Business Hours:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Monday - Friday: 8:00 AM - 5:00 PM'),
            const Text('Saturday: 9:00 AM - 1:00 PM'),
            const Text('Sunday: Closed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(BuildContext context) async {
    const phoneNumber = '+254743466295';
    const message =
        'Hello! I need support with the Digital Merry Go Round app.';
    final whatsappUrl =
        'https://wa.me/${phoneNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';

    try {
      // Try to open WhatsApp
      await AppHelpers.launchUrl(whatsappUrl);
    } catch (e) {
      // Fallback - show error message
      if (context.mounted) {
        AppHelpers.showErrorSnackBar(
          context,
          'Could not open WhatsApp. Please contact: $phoneNumber',
        );
      }
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last updated: October 2025',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Text(
                'Information We Collect',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Personal information (name, email, phone)'),
              Text('• Financial information (contributions, loans)'),
              Text('• Device information and usage data'),
              SizedBox(height: 16),
              Text(
                'How We Use Your Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Process contributions and loan applications'),
              Text('• Send notifications and updates'),
              Text('• Improve our services'),
              Text('• Comply with legal requirements'),
              SizedBox(height: 16),
              Text(
                'Data Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We use industry-standard encryption and security measures to protect your data.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last updated: October 2025',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Text(
                'Acceptance of Terms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'By using this app, you agree to these terms and conditions.',
              ),
              SizedBox(height: 16),
              Text(
                'User Responsibilities',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Make timely monthly contributions'),
              Text('• Provide accurate information'),
              Text('• Follow group rules and guidelines'),
              Text('• Maintain account security'),
              SizedBox(height: 16),
              Text(
                'Group Rules',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Monthly contributions are mandatory'),
              Text('• Late payments may incur penalties'),
              Text('• Loan applications must be justified'),
              Text('• Respect other members'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
