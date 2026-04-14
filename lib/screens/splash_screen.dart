import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeOutAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _fadeOutAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              _buildBackgroundShapes(isDark),

              Center(
                child: FadeTransition(
                  opacity: _fadeOutAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLogo(isDark),
                        const SizedBox(height: 40),
                        Text(
                          'SEYA Expert',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white : AppColors.lightText,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Professional Expertise on Demand',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes(bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.05)],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -100,
          right: -80,
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

        Positioned(
          top: 100,
          right: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.08),
            ),
          ),
        ),
      ],
    );
  }
}

