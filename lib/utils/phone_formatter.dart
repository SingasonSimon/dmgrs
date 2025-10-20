import 'package:flutter/services.dart';

class PhoneFormatter {
  static const String kenyaCountryCode = '+254';
  static const String kenyaPrefix = '254';

  /// Format phone number to Kenyan format (+254XXXXXXXXX)
  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';

    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Handle different input formats
    if (digits.startsWith('254')) {
      // Already has country code
      return '+$digits';
    } else if (digits.startsWith('0')) {
      // Remove leading 0 and add country code
      return '+254${digits.substring(1)}';
    } else if (digits.startsWith('7') || digits.startsWith('1')) {
      // Assume it's a local number starting with 7 or 1
      return '+254$digits';
    } else {
      // Default: add country code
      return '+254$digits';
    }
  }

  /// Validate Kenyan phone number
  static bool isValidKenyanPhone(String phone) {
    String formatted = formatPhoneNumber(phone);
    // Kenyan mobile numbers are +254 followed by 9 digits
    return RegExp(r'^\+254[17]\d{8}$').hasMatch(formatted);
  }

  /// Get display format for phone number
  static String getDisplayFormat(String phone) {
    String formatted = formatPhoneNumber(phone);
    if (formatted.length == 13) {
      // +254XXXXXXXXX
      return '${formatted.substring(0, 4)} ${formatted.substring(4, 7)} ${formatted.substring(7, 10)} ${formatted.substring(10)}';
    }
    return formatted;
  }

  /// Get input hint text
  static String getInputHint() {
    return '7XXXXXXXX or 1XXXXXXXX';
  }

  /// Get input formatters for TextField
  static List<TextInputFormatter> getInputFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      LengthLimitingTextInputFormatter(
        9,
      ), // Max 9 digits (7XXXXXXXX or 1XXXXXXXX)
    ];
  }
}
