import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool showPassword = false;
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
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> loginExpert() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      _showErrorSnackBar("Please fill in all fields");
      return;
    }

    setState(() => loading = true);

    try {
      // 1️⃣ Firebase Auth login
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        await FirebaseAuth.instance.signOut();
        throw Exception('Authentication failed. Please try again.');
      }

      final expertDoc = await FirebaseFirestore.instance
          .collection('experts')
          .doc(uid)
          .get();

      if (!expertDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw "Not an expert account";
      }

      if (expertDoc.data()?['role'] != 'expert') {
        await FirebaseAuth.instance.signOut();
        throw "Access denied";
      }

      // ✅ Login success - Navigate to AuthCheck to verify terms acceptance
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(_friendlyAuthError(e.code));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Not an expert') || msg.contains('Access denied')) {
        _showErrorSnackBar(msg.replaceAll('Exception: ', ''));
      } else {
        _showErrorSnackBar('Login failed. Please check your credentials.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Login failed. Please try again.';
    }
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
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE0E7FF),
                    const Color(0xFFF8FAFC),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs
            _buildBackgroundShapes(isDark, primaryColor),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
                      ),
                      child: _buildHeader(context, primaryColor),
                    ),
                    const SizedBox(height: 48),

                    // Glass form card
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic)),
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
                              // Email field
                              Text(
                                'Email Address',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ModernTextField(
                                controller: email,
                                hint: 'expert@example.com',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 28),

                              // Password field
                              Text(
                                'Password',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ModernTextField(
                                controller: password,
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: !showPassword,
                                suffixIcon: showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                onSuffixTap: () {
                                  setState(() => showPassword = !showPassword);
                                },
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),

                    // Login button
                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic)),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
                        ),
                        child: SizedBox(
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
                                      onTap: loginExpert,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Center(
                                        child: Text(
                                          'Sign In',
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
        // Logo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 28),

        // Title
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'Sign in to your expert account and connect with clients',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundShapes(bool isDark, Color primaryColor) {
    return Stack(
      children: [
        // Top right
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

        // Bottom left
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
}
