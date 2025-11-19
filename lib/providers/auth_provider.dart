import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == AppConstants.adminRole;
  bool get isMember => _currentUser?.role == AppConstants.memberRole;

  // Initialize auth provider
  AuthProvider() {
    _initializeAuth();
  }

  // Test-only constructor to bypass Firebase listeners and inject a user
  AuthProvider.test(UserModel user) {
    _currentUser = user;
    _isLoading = false;
  }

  // Initialize authentication state
  void _initializeAuth() {
    AuthService.authStateChanges.listen((user) async {
      print('AuthProvider: Auth state changed - User: ${user?.uid}');
      if (user != null) {
        // Load user data if we don't have current user or if it's a different user
        if (_currentUser == null || _currentUser!.userId != user.uid) {
          await _loadUserData(user.uid);
        }
      } else {
        // User signed out - clear all state
        print('AuthProvider: User signed out - clearing state');
        _currentUser = null;
        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final userModel = await AuthService.getCurrentUserModel();
      _currentUser = userModel;

      print(
        'AuthProvider: User loaded - ${userModel?.name} (${userModel?.role})',
      );
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Error loading user data - $e');
      _setError('Failed to load user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = AppConstants.memberRole,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userModel = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );

      if (userModel != null) {
        _currentUser = userModel;
        print('AuthProvider: Sign up successful - User: ${_currentUser?.name}');
        print('AuthProvider: User role: ${_currentUser?.role}');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('AuthProvider: Sign up error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();

      print('AuthProvider: Starting sign in for email: $email');
      final userModel = await AuthService.signIn(
        email: email,
        password: password,
      );

      print('AuthProvider: Sign in result - UserModel: ${userModel?.name}');
      if (userModel != null) {
        // Update the current user immediately
        _currentUser = userModel;
        print('AuthProvider: Setting current user to: ${_currentUser?.name}');
        print('AuthProvider: User role: ${_currentUser?.role}');
        print('AuthProvider: Is authenticated: $isAuthenticated');
        notifyListeners();
        return true;
      }
      print('AuthProvider: Sign in failed - userModel is null');
      return false;
    } catch (e) {
      print('AuthProvider: Sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('AuthProvider: Creating user with email: $email');
      final userCredential = await AuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        'AuthProvider: User created successfully: ${userCredential?.user?.uid}',
      );
      return userCredential;
    } catch (e) {
      print('AuthProvider: Create user error: $e');
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('AuthProvider: Starting sign out...');
      // Clear state first to prevent any race conditions
      _currentUser = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      // Then sign out from Firebase
      await AuthService.signOut();
      print('AuthProvider: Sign out successful');
    } catch (e) {
      print('AuthProvider: Sign out error: $e');
      // Ensure state is cleared even on error
      _currentUser = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? profileUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.updateProfile(
        name: name,
        phone: phone,
        profileUrl: profileUrl,
      );

      // Reload user data
      if (_currentUser != null) {
        await _loadUserData(_currentUser!.userId);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.deleteAccount(password);
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reload user data
  Future<void> reloadUser() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.userId);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => AuthService.isEmailVerified;

  // Refresh authentication state
  Future<void> refreshAuthState() async {
    try {
      await AuthService.reloadUser();
      final userModel = await AuthService.getCurrentUserModel();
      _currentUser = userModel;
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh authentication state: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  // Check if user is active
  bool get isUserActive {
    return _currentUser?.isActive ?? false;
  }

  // Get user display name
  String get userDisplayName {
    return _currentUser?.displayName ?? 'User';
  }

  // Get user initials
  String get userInitials {
    return _currentUser?.initials ?? 'U';
  }

  // Get user email
  String get userEmail {
    return _currentUser?.email ?? '';
  }

  // Get user phone
  String get userPhone {
    return _currentUser?.phone ?? '';
  }

  // Get user ID
  String get userId {
    return _currentUser?.userId ?? '';
  }

  // Get user joined date
  DateTime? get userJoinedDate {
    return _currentUser?.joinedAt;
  }

  // Get user last login
  DateTime? get userLastLogin {
    return _currentUser?.lastLoginAt;
  }

  // Get user consecutive misses
  int get userConsecutiveMisses {
    return _currentUser?.consecutiveMisses ?? 0;
  }

  // Get user last contribution date
  DateTime? get userLastContributionDate {
    return _currentUser?.lastContributionDate;
  }

  // Get user role
  String get userRole {
    return _currentUser?.role ?? AppConstants.memberRole;
  }
}
