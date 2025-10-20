import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class MpesaService {
  // Generate access token for M-Pesa API
  static Future<String?> getAccessToken() async {
    try {
      final String consumerKey = 'your_consumer_key'; // Replace with actual key
      final String consumerSecret =
          'your_consumer_secret'; // Replace with actual secret

      final String credentials = base64Encode(
        utf8.encode('$consumerKey:$consumerSecret'),
      );

      final response = await http.post(
        Uri.parse(
          '${AppConstants.mpesaSandboxUrl}/oauth/v1/generate?grant_type=client_credentials',
        ),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Failed to get access token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting access token: $e');
    }
  }

  // Generate password for STK Push
  static String generatePassword(
    String businessShortCode,
    String passkey,
    String timestamp,
  ) {
    final String passwordString = '$businessShortCode$passkey$timestamp';
    final bytes = utf8.encode(passwordString);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  // Generate timestamp
  static String generateTimestamp() {
    return DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
  }

  // Initiate STK Push
  static Future<Map<String, dynamic>?> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('Failed to get access token');
      }

      final String timestamp = generateTimestamp();
      final String password = generatePassword(
        AppConstants.mpesaBusinessShortCode,
        AppConstants.mpesaPasskey,
        timestamp,
      );

      // Clean phone number
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '254${cleanPhone.substring(1)}';
      } else if (!cleanPhone.startsWith('254')) {
        cleanPhone = '254$cleanPhone';
      }

      final Map<String, dynamic> requestBody = {
        'BusinessShortCode': AppConstants.mpesaBusinessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt(),
        'PartyA': cleanPhone,
        'PartyB': AppConstants.mpesaBusinessShortCode,
        'PhoneNumber': cleanPhone,
        'CallBackURL':
            'https://your-callback-url.com/callback', // Replace with actual callback URL
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };

      final response = await http.post(
        Uri.parse(
          '${AppConstants.mpesaSandboxUrl}/mpesa/stkpush/v1/processrequest',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'STK Push failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error initiating STK Push: $e');
    }
  }

  // Query STK Push status
  static Future<Map<String, dynamic>?> querySTKPushStatus({
    required String checkoutRequestId,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('Failed to get access token');
      }

      final String timestamp = generateTimestamp();
      final String password = generatePassword(
        AppConstants.mpesaBusinessShortCode,
        AppConstants.mpesaPasskey,
        timestamp,
      );

      final Map<String, dynamic> requestBody = {
        'BusinessShortCode': AppConstants.mpesaBusinessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      final response = await http.post(
        Uri.parse(
          '${AppConstants.mpesaSandboxUrl}/mpesa/stkpushquery/v1/query',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'STK Push query failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error querying STK Push status: $e');
    }
  }

  // Simulate STK Push for testing (sandbox mode)
  static Future<Map<String, dynamic>?> simulateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate mock response
      final Map<String, dynamic> mockResponse = {
        'MerchantRequestID':
            'mock_merchant_request_${DateTime.now().millisecondsSinceEpoch}',
        'CheckoutRequestID':
            'mock_checkout_request_${DateTime.now().millisecondsSinceEpoch}',
        'ResponseCode': '0',
        'ResponseDescription': 'Success. Request accepted for processing',
        'CustomerMessage': 'Success. Request accepted for processing',
      };

      return mockResponse;
    } catch (e) {
      throw Exception('Error simulating STK Push: $e');
    }
  }

  // Simulate STK Push query for testing
  static Future<Map<String, dynamic>?> simulateSTKPushQuery({
    required String checkoutRequestId,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate mock response
      final Map<String, dynamic> mockResponse = {
        'ResponseCode': '0',
        'ResponseDescription': 'The service request is processed successfully.',
        'MerchantRequestID':
            'mock_merchant_request_${DateTime.now().millisecondsSinceEpoch}',
        'CheckoutRequestID': checkoutRequestId,
        'ResultCode': '0',
        'ResultDesc': 'The service request is processed successfully.',
        'CallbackMetadata': {
          'Item': [
            {'Name': 'Amount', 'Value': 1000},
            {
              'Name': 'MpesaReceiptNumber',
              'Value': 'mock_receipt_${DateTime.now().millisecondsSinceEpoch}',
            },
            {'Name': 'Balance', 'Value': 50000},
            {
              'Name': 'TransactionDate',
              'Value': DateTime.now().millisecondsSinceEpoch,
            },
            {'Name': 'PhoneNumber', 'Value': 254712345678},
          ],
        },
      };

      return mockResponse;
    } catch (e) {
      throw Exception('Error simulating STK Push query: $e');
    }
  }

  // Process M-Pesa callback
  static Map<String, dynamic> processCallback(
    Map<String, dynamic> callbackData,
  ) {
    try {
      final body = callbackData['Body'];
      final stkCallback = body['stkCallback'];

      final resultCode = stkCallback['ResultCode'];
      final resultDesc = stkCallback['ResultDesc'];
      final merchantRequestId = stkCallback['MerchantRequestID'];
      final checkoutRequestId = stkCallback['CheckoutRequestID'];

      Map<String, dynamic>? callbackMetadata;
      if (stkCallback['CallbackMetadata'] != null) {
        callbackMetadata = {};
        final items = stkCallback['CallbackMetadata']['Item'] as List;
        for (var item in items) {
          callbackMetadata[item['Name']] = item['Value'];
        }
      }

      return {
        'success': resultCode == 0,
        'resultCode': resultCode,
        'resultDesc': resultDesc,
        'merchantRequestId': merchantRequestId,
        'checkoutRequestId': checkoutRequestId,
        'metadata': callbackMetadata,
      };
    } catch (e) {
      throw Exception('Error processing callback: $e');
    }
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return (cleanPhone.length == 10 && cleanPhone.startsWith('0')) ||
        (cleanPhone.length == 12 && cleanPhone.startsWith('254')) ||
        (cleanPhone.length == 13 && cleanPhone.startsWith('254'));
  }

  // Format phone number for M-Pesa
  static String formatPhoneForMpesa(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.startsWith('0')) {
      return '254${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('254')) {
      return cleanPhone;
    } else if (cleanPhone.startsWith('+254')) {
      return cleanPhone.substring(1);
    } else {
      return '254$cleanPhone';
    }
  }

  // Check if M-Pesa service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.mpesaSandboxUrl}/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get transaction status from result code
  static String getTransactionStatus(int resultCode) {
    switch (resultCode) {
      case 0:
        return 'Success';
      case 1:
        return 'Insufficient funds';
      case 2:
        return 'Less than minimum transaction value';
      case 3:
        return 'More than maximum transaction value';
      case 4:
        return 'Would exceed daily transfer limit';
      case 5:
        return 'Would exceed minimum balance';
      case 6:
        return 'Unresolved primary party';
      case 7:
        return 'Unresolved receiver party';
      case 8:
        return 'Would exceed maximum balance';
      case 11:
        return 'Debit account invalid';
      case 12:
        return 'Credit account invalid';
      case 13:
        return 'Unresolved debit account';
      case 14:
        return 'Unresolved credit account';
      case 15:
        return 'Duplicate detection';
      case 16:
        return 'Internal failure';
      case 17:
        return 'Unresolved initiator';
      case 18:
        return 'Blocked';
      case 19:
        return 'System maintenance';
      case 20:
        return 'Network timeout';
      case 26:
        return 'Transaction cancelled by user';
      default:
        return 'Unknown error';
    }
  }
}
