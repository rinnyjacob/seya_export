import 'dart:convert';
import 'package:http/http.dart' as http;

/// MessageCentral OTP Service
/// Customer ID: C-423EB5C2725243B
class MessageCentralService {
  static const String _customerId = 'C-423EB5C2725243B';
  static const String _authToken =
      'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLTQyM0VCNUMyNzI1MjQzQiIsImlhdCI6MTc3NTA0NjYyMSwiZXhwIjoxOTMyNzI2NjIxfQ.MxknbLyOdF2MKsYlo-VhqoSeYmmRkNa3quy5X6U9NLq49GxeZ_ufuJpVDX35mqAuoJhi9rH4WnR6r5SK88LgtA';
  static const String _baseUrl = 'https://cpaas.messagecentral.com';

  static const int _otpLength = 6;
  static const int _otpExpiry = 120; // seconds

  /// Send OTP to phone number (with country code, e.g. +919999999999)
  /// Returns verificationId on success, throws on failure
  static Future<String> sendOtp(String phoneNumber) async {
    // Strip leading + if present; API wants just digits
    final phone = phoneNumber.replaceAll('+', '').trim();

    final uri = Uri.parse(
      '$_baseUrl/verification/v2/verification/send'
      '?countryCode=${_extractCountryCode(phone)}'
      '&customerId=$_customerId'
      '&flowType=SMS'
      '&mobileNumber=${_extractLocalNumber(phone)}'
      '&otpLength=$_otpLength'
      '&otpType=NUMERIC'
      '&expiry=$_otpExpiry',
    );

    final response = await http.post(
      uri,
      headers: {
        'authToken': _authToken,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final verificationId = data?['verificationId']?.toString();
      if (verificationId == null || verificationId.isEmpty) {
        throw 'OTP send failed: verificationId missing in response';
      }
      return verificationId;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = body?['message'] ?? 'Unknown error';
      throw 'OTP send failed (${ response.statusCode}): $msg';
    }
  }

  /// Validate OTP entered by user
  /// Returns true if valid, false if invalid, throws on network error
  static Future<bool> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/verification/v2/verification/validateOtp'
      '?customerId=$_customerId'
      '&verificationId=$verificationId'
      '&code=$otp',
    );

    final response = await http.get(
      uri,
      headers: {
        'authToken': _authToken,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final responseCode = body['responseCode']?.toString();
      // MessageCentral returns responseCode 200 for success
      return responseCode == '200';
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = body?['message'] ?? 'Unknown error';
      throw 'OTP verification failed (${response.statusCode}): $msg';
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Extracts country code from full number string (e.g. "919999999999" → "91")
  static String _extractCountryCode(String fullNumber) {
    if (fullNumber.startsWith('91') && fullNumber.length == 12) return '91';
    if (fullNumber.startsWith('1') && fullNumber.length == 11) return '1';
    // Default to India if uncertain
    return '91';
  }

  /// Extracts local number (last 10 digits)
  static String _extractLocalNumber(String fullNumber) {
    if (fullNumber.length > 10) {
      return fullNumber.substring(fullNumber.length - 10);
    }
    return fullNumber;
  }
}
