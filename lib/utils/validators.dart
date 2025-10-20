import 'package:flutter/material.dart';
import 'phone_formatter.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  // Phone number validation (Kenyan format)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    if (!PhoneFormatter.isValidKenyanPhone(value)) {
      return 'Please enter a valid Kenyan phone number (e.g., 712345678)';
    }

    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 1000000) {
      return 'Amount is too large';
    }

    return null;
  }

  // Loan amount validation
  static String? validateLoanAmount(String? value, double availableAmount) {
    final amountError = validateAmount(value);
    if (amountError != null) {
      return amountError;
    }

    final amount = double.parse(value!);
    if (amount > availableAmount) {
      return 'Loan amount cannot exceed available pool amount (KSh ${availableAmount.toStringAsFixed(0)})';
    }

    if (amount < 1000) {
      return 'Minimum loan amount is KSh 1,000';
    }

    return null;
  }

  // Description validation
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.length > 500) {
      return 'Description must be less than 500 characters';
    }

    return null;
  }

  // Meeting link validation
  static String? validateMeetingLink(String? value) {
    if (value == null || value.isEmpty) {
      return 'Meeting link is required';
    }

    final urlRegex = RegExp(r'^https?:\/\/.+\..+');
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid meeting link';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Form validation helper
  static bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  // Save form helper
  static void saveForm(GlobalKey<FormState> formKey) {
    formKey.currentState?.save();
  }
}
