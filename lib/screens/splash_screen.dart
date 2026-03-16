import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _opacityController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleController.forward();
    _rotateController.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _opacityController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _opacityController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_opacityController),
        child: Container(
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.5, end: 1.0)
                          .animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut)),
                      child: RotationTransition(
                        turns: Tween<double>(begin: 0, end: 1)
                            .animate(CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut)),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.1))
                              .animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut)),
                          child: _buildLogo(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
                      ),
                      child: Column(
                        children: [
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
                  ],
                ),
              ),

              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
                    ),
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
              ),
            ],
          ),
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

