// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../theme/app_colors.dart';
// import '../widgets/modern_text_field.dart';
// import '../widgets/glass_card.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
//   final email = TextEditingController();
//   final password = TextEditingController();
//   bool loading = false;
//   bool showPassword = false;
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//
//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//
//     _fadeController.forward();
//     Future.delayed(const Duration(milliseconds: 200), () {
//       _slideController.forward();
//     });
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     email.dispose();
//     password.dispose();
//     super.dispose();
//   }
//
//   Future<void> loginExpert() async {
//     if (email.text.isEmpty || password.text.isEmpty) {
//       _showErrorSnackBar("Please fill in all fields");
//       return;
//     }
//
//     setState(() => loading = true);
//
//     try {
//       // 1️⃣ Firebase Auth login
//       final cred = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(
//         email: email.text.trim(),
//         password: password.text.trim(),
//       );
//
//       final uid = cred.user!.uid;
//
//       // 2️⃣ Verify expert role in Firestore
//       final expertDoc = await FirebaseFirestore.instance
//           .collection('experts')
//           .doc(uid)
//           .get();
//
//       if (!expertDoc.exists) {
//         await FirebaseAuth.instance.signOut();
//         throw "Not an expert account";
//       }
//
//       if (expertDoc.data()?['role'] != 'expert') {
//         await FirebaseAuth.instance.signOut();
//         throw "Access denied";
//       }
//
//       // ✅ Login success - Navigate to AuthCheck to verify terms acceptance
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/auth');
//       }
//     } catch (e) {
//       _showErrorSnackBar(e.toString());
//     }
//
//     setState(() => loading = false);
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: AppColors.lightError,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
//
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: isDark
//                 ? [
//                     const Color(0xFF0F172A),
//                     const Color(0xFF1E293B),
//                     const Color(0xFF0F172A),
//                   ]
//                 : [
//                     const Color(0xFFF8FAFC),
//                     const Color(0xFFE0E7FF),
//                     const Color(0xFFF8FAFC),
//                   ],
//           ),
//         ),
//         child: Stack(
//           children: [
//             // Decorative blobs
//             _buildBackgroundShapes(isDark, primaryColor),
//
//             // Main content
//             SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header
//                     FadeTransition(
//                       opacity: Tween<double>(begin: 0, end: 1).animate(
//                         CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
//                       ),
//                       child: _buildHeader(context, primaryColor),
//                     ),
//                     const SizedBox(height: 48),
//
//                     // Glass form card
//                     SlideTransition(
//                       position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
//                           .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic)),
//                       child: FadeTransition(
//                         opacity: Tween<double>(begin: 0, end: 1).animate(
//                           CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
//                         ),
//                         child: GlassCard(
//                           borderRadius: 28,
//                           blur: 12,
//                           padding: const EdgeInsets.all(28),
//                           margin: const EdgeInsets.only(bottom: 24),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Email field
//                               Text(
//                                 'Email Address',
//                                 style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                               ),
//                               const SizedBox(height: 12),
//                               ModernTextField(
//                                 controller: email,
//                                 hint: 'expert@example.com',
//                                 prefixIcon: Icons.mail_outline,
//                                 keyboardType: TextInputType.emailAddress,
//                               ),
//                               const SizedBox(height: 28),
//
//                               // Password field
//                               Text(
//                                 'Password',
//                                 style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                               ),
//                               const SizedBox(height: 12),
//                               ModernTextField(
//                                 controller: password,
//                                 hint: '••••••••',
//                                 prefixIcon: Icons.lock_outline,
//                                 obscureText: !showPassword,
//                                 suffixIcon: showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                                 onSuffixTap: () {
//                                   setState(() => showPassword = !showPassword);
//                                 },
//                               ),
//
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // Login button
//                     SlideTransition(
//                       position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
//                           .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic)),
//                       child: FadeTransition(
//                         opacity: Tween<double>(begin: 0, end: 1).animate(
//                           CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
//                         ),
//                         child: SizedBox(
//                           width: double.infinity,
//                           height: 56,
//                           child: loading
//                               ? Container(
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
//                                     ),
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                   child: Center(
//                                     child: SizedBox(
//                                       width: 24,
//                                       height: 24,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2.5,
//                                         valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               : Container(
//                                   decoration: BoxDecoration(
//                                     gradient: LinearGradient(
//                                       colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
//                                     ),
//                                     borderRadius: BorderRadius.circular(16),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: primaryColor.withValues(alpha: 0.3),
//                                         blurRadius: 16,
//                                         spreadRadius: 2,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Material(
//                                     color: Colors.transparent,
//                                     child: InkWell(
//                                       onTap: loginExpert,
//                                       borderRadius: BorderRadius.circular(16),
//                                       child: Center(
//                                         child: Text(
//                                           'Sign In',
//                                           style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                                                 color: Colors.white,
//                                                 fontWeight: FontWeight.w700,
//                                                 letterSpacing: 0.5,
//                                               ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader(BuildContext context, Color primaryColor) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Logo
//         Container(
//           width: 64,
//           height: 64,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: LinearGradient(
//               colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: primaryColor.withValues(alpha: 0.3),
//                 blurRadius: 24,
//                 spreadRadius: 4,
//               ),
//             ],
//           ),
//           child: const Icon(
//             Icons.auto_awesome,
//             color: Colors.white,
//             size: 32,
//           ),
//         ),
//         const SizedBox(height: 28),
//
//         // Title
//         Text(
//           'Welcome Back',
//           style: Theme.of(context).textTheme.headlineLarge?.copyWith(
//             fontWeight: FontWeight.w800,
//             letterSpacing: -0.5,
//           ),
//         ),
//         const SizedBox(height: 12),
//
//         // Subtitle
//         Text(
//           'Sign in to your expert account and connect with clients',
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//             color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
//             height: 1.5,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBackgroundShapes(bool isDark, Color primaryColor) {
//     return Stack(
//       children: [
//         // Top right
//         Positioned(
//           top: -100,
//           right: -100,
//           child: Container(
//             width: 300,
//             height: 300,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.05)],
//               ),
//             ),
//           ),
//         ),
//
//         // Bottom left
//         Positioned(
//           bottom: -80,
//           left: -80,
//           child: Container(
//             width: 250,
//             height: 250,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: RadialGradient(
//                 colors: [primaryColor.withValues(alpha: 0.15), primaryColor.withValues(alpha: 0.02)],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seya_export/home/expert_home_screen.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final phone = TextEditingController();
  final otp = TextEditingController();

  bool loading = false;
  bool otpSent = false;
  String? verificationSessionId;

  // Resend OTP timer
  Timer? _resendTimer;
  int _resendSeconds = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  bool _isValidIndianMobile(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 10;
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

// Replace placeholder URLs/constants with MessageCentral config
  static const String _messageCentralAuthToken =
      'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLTQyM0VCNUMyNzI1MjQzQiIsImlhdCI6MTc1ODYwMzg0MywiZXhwIjoxOTE2MjgzODQzfQ.7RirQIul1-gf0O5b6KIwuSy6x5WfzT7KPVNB-2iLf44DJ6Y8Zv3eMlgMe9Pbx6Hp200t0zbgOnzIHWoR9V3q7g';
  static const String _countryCode = '91';

// Replace _postJson with this simple POST helper for MessageCentral
//   Future<Map<String, dynamic>> _postMessageCentral(Uri uri) async {
//
//     debugPrint("📤 MessageCentral API Request");
//     log("URL: $uri");
//     debugPrint("Headers: {authToken: $_messageCentralAuthToken}");
//
//     final response = await http.post(
//       uri,
//       headers: {
//         'authToken': _messageCentralAuthToken,
//         'Content-Type': 'application/json',
//       },
//     );
//
//     debugPrint("📥 Response Status: ${response.statusCode}");
//     debugPrint("📥 Response Body: ${response.body}");
//
//     Map<String, dynamic> data = {};
//
//     try {
//       final decoded = jsonDecode(response.body);
//       if (decoded is Map<String, dynamic>) {
//         data = decoded;
//         debugPrint("✅ Parsed JSON: $data");
//       }
//     } catch (e) {
//       debugPrint("❌ JSON Parse Error: $e");
//     }
//
//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       final error =
//           data['message']?.toString() ??
//               data['error']?.toString() ??
//               'Request failed (${response.statusCode})';
//
//       debugPrint("🚨 MessageCentral Error: $error");
//
//       throw error;
//     }
//
//     return data;
//   }
  Future<Map<String, dynamic>> _postMessageCentral(Uri uri,
      {bool get = false}) async {
    debugPrint('📤 MessageCentral API Request');
    debugPrint('URL: $uri');
    debugPrint('Method: ${get ? "GET" : "POST"}');

    http.Response response;

    if (get) {
      response = await http.get(
        uri,
        headers: {
          'authToken': _messageCentralAuthToken.trim(),
        },
      );
    } else {
      response = await http.post(
        uri,
        headers: {
          'authToken': _messageCentralAuthToken.trim(),
        },
      );
    }

    debugPrint('📥 Response Status: ${response.statusCode}');
    debugPrint('📥 headers: ${response.headers}');
    debugPrint(
        '📥 Response Body: ${response.body.isEmpty ? "<empty>" : response.body}');

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (e) {
        debugPrint('⚠️ JSON parse failed: $e');
      }
    }

    if (response.statusCode == 401) {
      throw 'Unauthorized (401): invalid/expired MessageCentral auth token or wrong account permissions.';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw data['message']?.toString() ??
          data['error']?.toString() ??
          'Request failed (${response.statusCode})';
    }

    return data;
  }

  Future<bool> checkExpertExists(String phoneNumber) async {
    final expertsRef = FirebaseFirestore.instance.collection('experts');

    final query =
        await expertsRef.where('phone', isEqualTo: phoneNumber).limit(1).get();

    return query.docs.isNotEmpty;
  }

  Future<void> sendOtp() async {
    if (!_isValidIndianMobile(phone.text.trim())) {
      _showErrorSnackBar('Enter valid 10-digit mobile number');
      return;
    }

    final mobileDigits = phone.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final phoneNumber =
        "+91${phone.text.trim().replaceAll(RegExp(r'[^0-9]'), '')}";

    setState(() => loading = true);

    try {
      final expertExists = await checkExpertExists(mobileDigits);

      if (!expertExists) {
        throw "This number is not registered as an expert";
      }

      // final mobileDigits = phoneNumber.replaceAll("+91", "");

      final uri = Uri.parse(
        'https://cpaas.messagecentral.com/verification/v3/send'
        '?countryCode=$_countryCode'
        '&flowType=SMS'
        '&mobileNumber=$mobileDigits',
      );

      final data = await _postMessageCentral(uri);

      // Commonly verificationId / data.verificationId (depends on API response shape)
      final verificationId = data['verificationId']?.toString() ??
          (data['data'] is Map
              ? data['data']['verificationId']?.toString()
              : null);

      if (verificationId == null || verificationId.isEmpty) {
        throw data['message']?.toString() ??
            'Missing verificationId from MessageCentral';
      }

      verificationSessionId = verificationId;

      if (!mounted) return;
      setState(() {
        otpSent = true;
        otp.clear();
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'OTP sent successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Future<DocumentSnapshot?> getExpertByPhone(String phoneNumber) async {
  //   final query = await FirebaseFirestore.instance
  //       .collection('experts')
  //       .where('phone', isEqualTo: phoneNumber)
  //       .limit(1)
  //       .get();
  //
  //   if (query.docs.isEmpty) return null;
  //
  //   return query.docs.first;
  // }

  Future<void> loginAfterOtp() async {
    try {
      print("STEP 1: Login Start");

      final phoneNumber = phone.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

      print("STEP 2: Phone -> $phoneNumber");

      // find expert
      final expertDoc = await getExpertByPhone(phoneNumber);

      if (expertDoc == null) {
        throw "Expert not found";
      }

      print("STEP 3: Expert Found");

      // Firebase login
      final cred = await FirebaseAuth.instance.signInAnonymously();

      final firebaseUid = cred.user!.uid;

      print("STEP 4: Firebase UID -> $firebaseUid");

      // store expert data using firebase UID as document id
      await FirebaseFirestore.instance
          .collection('experts')
          .doc(firebaseUid)
          .set({
        ...expertDoc.data() as Map<String, dynamic>,
        "firebaseUid": firebaseUid,
        "lastLoginAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("STEP 5: Expert document updated");
    } catch (e) {
      print("LOGIN ERROR: $e");
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getExpertByPhone(String phoneNumber) async {
    try {
      print("STEP A: Searching expert with phone -> $phoneNumber");

      final query = await FirebaseFirestore.instance
          .collection('experts')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      print("STEP B: Query Docs Length -> ${query.docs.length}");

      if (query.docs.isEmpty) return null;

      print("STEP C: Expert Found");

      return query.docs.first;
    } catch (e) {
      print("GET EXPERT ERROR: $e");

      return null;
    }
  }

  Future<void> verifyOtpAndLogin() async {
    if (!otpSent || verificationSessionId == null) {
      _showErrorSnackBar('Please request OTP first');
      return;
    }

    final code = otp.text.trim();
    if (code.length < 4) {
      _showErrorSnackBar('Please enter valid OTP');
      return;
    }

    setState(() => loading = true);

    try {
      final uri = Uri.parse(
        'https://cpaas.messagecentral.com/verification/v3/validateOtp'
        '?verificationId=$verificationSessionId'
        '&code=$code'
        "&flowType=SMS",
      );

      log('fhgfsdkjgsdj ${uri}');
      final data = await _postMessageCentral(uri, get: true);
      log('dhrhty ${data}');

      // MessageCentral success flag can vary by account/version
      final isSuccess = data['responseCode'] == 200 ||
          data['status']?.toString().toLowerCase() == 'success' ||
          data['verified'] == true;

      if (!isSuccess) {
        throw data['message']?.toString() ?? 'Invalid OTP';
      }

      // IMPORTANT:
      // MessageCentral only verifies phone OTP.
      // To login into Firebase, you still need a trusted backend
      // to mint Firebase custom token for this verified phone.
      //
      // Example expected from your backend:
      // final customToken = await yourBackendCreateFirebaseToken(phoneNumber);
      // await _signInWithCustomTokenAndValidateExpert(customToken);

      _showErrorSnackBar(
        'OTP verified. Now connect backend to issue Firebase custom token.',
      );
      // loginAfterOtp();
      // await loginUserWithPhone(phone.text);
      await loginAfterOtp();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ExpertHomeScreen(),
        ),
      );
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signInWithCustomTokenAndValidateExpert(
      String customToken) async {
    final cred = await FirebaseAuth.instance.signInWithCustomToken(customToken);
    final uid = cred.user?.uid;
    if (uid == null) throw 'Login failed. Missing user id.';

    final expertDoc =
        await FirebaseFirestore.instance.collection('experts').doc(uid).get();
    if (!expertDoc.exists) {
      await FirebaseAuth.instance.signOut();
      throw 'Not an expert account';
    }
    if (expertDoc.data()?['role'] != 'expert') {
      await FirebaseAuth.instance.signOut();
      throw 'Access denied';
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
  }

  void _changeNumber() {
    setState(() {
      otpSent = false;
      verificationSessionId = null;
      otp.clear();
    });
    _resendTimer?.cancel();
    _resendSeconds = 0;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.lightError,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A)
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFE0E7FF),
                    Color(0xFFF8FAFC)
                  ],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundShapes(primaryColor),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
                      ),
                      child: _buildHeader(context, primaryColor),
                    ),
                    const SizedBox(height: 48),
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
                        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
                      ),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
                        ),
                        child: GlassCard(
                          borderRadius: 28,
                          blur: 12,
                          padding: const EdgeInsets.all(28),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ModernTextField(
                                controller: phone,
                                hint: '9876543210',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              if (otpSent) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'OTP',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ModernTextField(
                                  controller: otp,
                                  hint: 'Enter OTP',
                                  prefixIcon: Icons.lock_outline,
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: loading ? null : _changeNumber,
                                      child: const Text('Change number'),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: (loading || _resendSeconds > 0) ? null : sendOtp,
                                      child: Text(
                                        _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend OTP',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: loading
                          ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      )
                          : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            // onTap: otpSent ? verifyOtpAndLogin : sendOtp,
                              onTap: () async {
                                try {

                                  print("BUTTON CLICKED");

                                  // await loginUserWithPhone(phone.text);
                                  await loginAfterOtp();

                                  print("LOGIN SUCCESS");

                                  if (!mounted) return;

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ExpertHomeScreen(),
                                    ),
                                  );

                                } catch (e) {

                                  print("NAVIGATION ERROR: $e");

                                }
                              },
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: Text(
                                otpSent ? 'Verify OTP' : 'Send OTP',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: isDark ? AppColors.darkGradient : AppColors.lightGradient),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in with OTP to your expert account',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundShapes(Color primaryColor) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.05)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primaryColor.withValues(alpha: 0.15), primaryColor.withValues(alpha: 0.02)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> loginUserWithPhone(String phoneNumber) async {
    try {
      // Fetch expert document by phone
      final expertDoc = await getExpertByPhone(phoneNumber);
      if (expertDoc == null) {
        throw "Expert not found";
      }
      // Ensure user is authenticated
      if (FirebaseAuth.instance.currentUser == null) {
        throw "User not authenticated";
      }
      final firebaseUid = FirebaseAuth.instance.currentUser!.uid;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(firebaseUid);
      print("[loginUserWithPhone] Setting user doc for UID: $firebaseUid");
      await userDocRef.set({
        ...expertDoc.data() as Map<String, dynamic>,
        "lastLoginAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("[loginUserWithPhone] User doc set/updated successfully.");
    } catch (e) {
      print("USER LOGIN ERROR: $e");
      rethrow;
    }
  }
}
