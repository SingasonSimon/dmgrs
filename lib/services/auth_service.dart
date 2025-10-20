import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = AppConstants.memberRole,
  }) async {
    try {
      // Create user with email and password
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Create user model
        final userModel = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
          joinedAt: DateTime.now(),
          status: 'active',
        );

        // Save user to Firestore
        await FirestoreService.createUser(userModel);

        // Send email verification
        await user.sendEmailVerification();

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Starting sign in for email: $email');
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      print('AuthService: Firebase auth successful - User ID: ${user?.uid}');
      if (user != null) {
        // Get user data from Firestore
        print('AuthService: Fetching user data from Firestore...');
        final userModel = await FirestoreService.getUser(user.uid);
        print('AuthService: User data from Firestore: ${userModel?.name}');

        if (userModel != null) {
          // Update last login time
          print('AuthService: Updating last login time...');
          final updatedUser = userModel.copyWith(lastLoginAt: DateTime.now());
          await FirestoreService.updateUser(updatedUser);
          print(
            'AuthService: Sign in successful - returning user: ${updatedUser.name}',
          );
          return updatedUser;
        } else {
          print('AuthService: User data not found in Firestore');
        }
      }
      print('AuthService: Sign in failed - no user returned');
      return null;
    } on FirebaseAuthException catch (e) {
      print('AuthService: Firebase auth exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('AuthService: General exception: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Create user with email and password (for admin use)
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Creating user with email: $email');
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('AuthService: User created successfully: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('AuthService: Firebase auth exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('AuthService: General exception: $e');
      throw Exception('User creation failed: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Change password
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Update user profile
  static Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Get current user data
      final userModel = await FirestoreService.getUser(user.uid);
      if (userModel == null) {
        throw Exception('User data not found');
      }

      // Update user data
      final updatedUser = userModel.copyWith(
        name: name ?? userModel.name,
        phone: phone ?? userModel.phone,
        profileUrl: profileUrl ?? userModel.profileUrl,
      );

      await FirestoreService.updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Delete user account
  static Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .delete();

      // Delete user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send email verification: $e');
    }
  }

  // Reload user data
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user: $e');
    }
  }

  // Get user role
  static Future<String?> getUserRole(String userId) async {
    try {
      final userModel = await FirestoreService.getUser(userId);
      return userModel?.role;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  // Check if user is admin
  static Future<bool> isAdmin(String userId) async {
    try {
      final role = await getUserRole(userId);
      return role == AppConstants.adminRole;
    } catch (e) {
      return false;
    }
  }

  // Check if user is member
  static Future<bool> isMember(String userId) async {
    try {
      final role = await getUserRole(userId);
      return role == AppConstants.memberRole;
    } catch (e) {
      return false;
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  // Get current user model
  static Future<UserModel?> getCurrentUserModel() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await FirestoreService.getUser(user.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user model: $e');
    }
  }

  // Stream of current user model
  static Stream<UserModel?> getCurrentUserModelStream() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        return await FirestoreService.getUser(user.uid);
      }
      return null;
    });
  }
}
