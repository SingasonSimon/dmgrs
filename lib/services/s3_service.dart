import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class S3Service {
  // AWS S3 configuration
  static const String _region = AppConstants.s3Region;
  static const String _bucketName = AppConstants.s3BucketName;
  static const String _service = 's3';
  static const String _algorithm = 'AWS4-HMAC-SHA256';

  // AWS credentials (should be stored securely in environment variables)
  static const String _accessKeyId =
      'your_access_key_id'; // Replace with actual key
  static const String _secretAccessKey =
      'your_secret_access_key'; // Replace with actual key

  // Upload file to S3
  static Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String contentType,
    String? folder,
  }) async {
    try {
      final String key = folder != null ? '$folder/$fileName' : fileName;
      final String url = 'https://$_bucketName.s3.$_region.amazonaws.com/$key';

      // Create the request
      final request = http.Request('PUT', Uri.parse(url));
      request.headers['Content-Type'] = contentType;
      request.headers['Content-Length'] = fileBytes.length.toString();
      request.bodyBytes = fileBytes;

      // Add AWS signature
      _addAwsSignature(request, key, contentType, fileBytes);

      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return url;
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      throw Exception('Error uploading file to S3: $e');
    }
  }

  // Download file from S3
  static Future<Uint8List?> downloadFile(String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading file from S3: $e');
    }
  }

  // Delete file from S3
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final key = uri.path.substring(1); // Remove leading slash

      final request = http.Request('DELETE', uri);
      _addAwsSignature(request, key, '', Uint8List(0));

      final response = await request.send();
      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting file from S3: $e');
    }
  }

  // Generate presigned URL for file upload
  static Future<String?> generatePresignedUploadUrl({
    required String fileName,
    required String contentType,
    String? folder,
    int expirationMinutes = 60,
  }) async {
    try {
      final String key = folder != null ? '$folder/$fileName' : fileName;
      final DateTime expiration = DateTime.now().add(
        Duration(minutes: expirationMinutes),
      );

      final String policy = _createUploadPolicy(key, contentType, expiration);
      final String signature = _createSignature(policy);

      final String url = 'https://$_bucketName.s3.$_region.amazonaws.com/$key';
      final String presignedUrl =
          '$url?AWSAccessKeyId=$_accessKeyId&Policy=$policy&Signature=$signature';

      return presignedUrl;
    } catch (e) {
      throw Exception('Error generating presigned URL: $e');
    }
  }

  // Generate presigned URL for file download
  static Future<String?> generatePresignedDownloadUrl({
    required String fileName,
    String? folder,
    int expirationMinutes = 60,
  }) async {
    try {
      final String key = folder != null ? '$folder/$fileName' : fileName;
      final DateTime expiration = DateTime.now().add(
        Duration(minutes: expirationMinutes),
      );

      final String stringToSign = _createDownloadStringToSign(key, expiration);
      final String signature = _createSignature(stringToSign);

      final String url = 'https://$_bucketName.s3.$_region.amazonaws.com/$key';
      final String presignedUrl =
          '$url?AWSAccessKeyId=$_accessKeyId&Expires=${expiration.millisecondsSinceEpoch ~/ 1000}&Signature=$signature';

      return presignedUrl;
    } catch (e) {
      throw Exception('Error generating presigned download URL: $e');
    }
  }

  // List files in a folder
  static Future<List<String>> listFiles({String? folder}) async {
    try {
      final String prefix = folder != null ? '$folder/' : '';
      final String url =
          'https://$_bucketName.s3.$_region.amazonaws.com/?list-type=2&prefix=$prefix';

      final request = http.Request('GET', Uri.parse(url));
      _addAwsSignature(request, '', '', Uint8List(0));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return _parseFileList(responseBody);
      } else {
        throw Exception('List files failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error listing files from S3: $e');
    }
  }

  // Add AWS signature to request
  static void _addAwsSignature(
    http.Request request,
    String key,
    String contentType,
    Uint8List body,
  ) {
    final DateTime now = DateTime.now().toUtc();
    final String dateStamp = _formatDate(now);
    final String amzDate = _formatDateTime(now);

    // Create canonical request
    final String canonicalRequest = _createCanonicalRequest(
      request.method,
      '/$key',
      '',
      request.headers,
      _sha256Hash(body),
    );

    // Create string to sign
    final String stringToSign = _createStringToSign(
      amzDate,
      dateStamp,
      canonicalRequest,
    );

    // Create signature
    final String signature = _createSignature(stringToSign, dateStamp);

    // Add authorization header
    request.headers['Authorization'] =
        '$_algorithm Credential=$_accessKeyId/$dateStamp/$_region/$_service/aws4_request, SignedHeaders=${_getSignedHeaders(request.headers)}, Signature=$signature';
    request.headers['X-Amz-Date'] = amzDate;
  }

  // Create canonical request
  static String _createCanonicalRequest(
    String method,
    String uri,
    String queryString,
    Map<String, String> headers,
    String payloadHash,
  ) {
    final String canonicalHeaders = _getCanonicalHeaders(headers);
    final String signedHeaders = _getSignedHeaders(headers);

    return [
      method,
      uri,
      queryString,
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');
  }

  // Create string to sign
  static String _createStringToSign(
    String amzDate,
    String dateStamp,
    String canonicalRequest,
  ) {
    return [
      _algorithm,
      amzDate,
      '$dateStamp/$_region/$_service/aws4_request',
      _sha256Hash(utf8.encode(canonicalRequest)),
    ].join('\n');
  }

  // Create signature
  static String _createSignature(String stringToSign, [String? dateStamp]) {
    if (dateStamp != null) {
      // For AWS4 signature
      final List<int> kDate = _hmacSha256(
        utf8.encode('AWS4$_secretAccessKey'),
        utf8.encode(dateStamp),
      );
      final List<int> kRegion = _hmacSha256(kDate, utf8.encode(_region));
      final List<int> kService = _hmacSha256(kRegion, utf8.encode(_service));
      final List<int> kSigning = _hmacSha256(
        kService,
        utf8.encode('aws4_request'),
      );
      final List<int> signature = _hmacSha256(
        kSigning,
        utf8.encode(stringToSign),
      );
      return _hexEncode(signature);
    } else {
      // For simple signature (legacy)
      final List<int> signature = _hmacSha256(
        utf8.encode(_secretAccessKey),
        utf8.encode(stringToSign),
      );
      return _hexEncode(signature);
    }
  }

  // Create upload policy
  static String _createUploadPolicy(
    String key,
    String contentType,
    DateTime expiration,
  ) {
    final Map<String, dynamic> policy = {
      'expiration': expiration.toIso8601String(),
      'conditions': [
        {'bucket': _bucketName},
        {'key': key},
        {'Content-Type': contentType},
        ['content-length-range', 0, 10485760], // 10MB max
      ],
    };

    return base64Encode(utf8.encode(json.encode(policy)));
  }

  // Create download string to sign
  static String _createDownloadStringToSign(String key, DateTime expiration) {
    return 'GET\n\n\n${expiration.millisecondsSinceEpoch ~/ 1000}\n/$_bucketName/$key';
  }

  // Get canonical headers
  static String _getCanonicalHeaders(Map<String, String> headers) {
    final List<String> sortedHeaders = headers.keys.toList()..sort();
    final List<String> canonicalHeaders = [];

    for (String header in sortedHeaders) {
      final String value = headers[header]?.toLowerCase().trim() ?? '';
      canonicalHeaders.add('$header:$value');
    }

    return '${canonicalHeaders.join('\n')}\n';
  }

  // Get signed headers
  static String _getSignedHeaders(Map<String, String> headers) {
    final List<String> sortedHeaders = headers.keys.toList()..sort();
    return sortedHeaders.join(';');
  }

  // Parse file list from XML response
  static List<String> _parseFileList(String xmlResponse) {
    final List<String> files = [];
    final RegExp keyRegex = RegExp(r'<Key>(.*?)</Key>');
    final Iterable<RegExpMatch> matches = keyRegex.allMatches(xmlResponse);

    for (RegExpMatch match in matches) {
      files.add(match.group(1)!);
    }

    return files;
  }

  // Utility methods
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z';
  }

  static String _sha256Hash(List<int> data) {
    final Digest digest = sha256.convert(data);
    return _hexEncode(digest.bytes);
  }

  static List<int> _hmacSha256(List<int> key, List<int> data) {
    final Hmac hmac = Hmac(sha256, key);
    final Digest digest = hmac.convert(data);
    return digest.bytes;
  }

  static String _hexEncode(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
  }

  // Simulate S3 operations for testing (when AWS credentials are not available)
  static Future<String?> simulateUpload({
    required Uint8List fileBytes,
    required String fileName,
    required String contentType,
    String? folder,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate mock URL
      final String key = folder != null ? '$folder/$fileName' : fileName;
      final String mockUrl =
          'https://$_bucketName.s3.$_region.amazonaws.com/$key';

      // In a real implementation, you would save the file to local storage or return a mock URL
      return mockUrl;
    } catch (e) {
      throw Exception('Error simulating S3 upload: $e');
    }
  }

  // Check if S3 service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('https://$_bucketName.s3.$_region.amazonaws.com/'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 ||
          response.statusCode == 403; // 403 means bucket exists but no access
    } catch (e) {
      return false;
    }
  }

  // Get file size from URL
  static Future<int?> getFileSize(String fileUrl) async {
    try {
      final response = await http.head(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        return contentLength != null ? int.tryParse(contentLength) : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if file exists
  static Future<bool> fileExists(String fileUrl) async {
    try {
      final response = await http.head(Uri.parse(fileUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
