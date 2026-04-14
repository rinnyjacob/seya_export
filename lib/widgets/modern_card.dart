import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool showGradient;
  final List<Color>? gradientColors;
  final BorderRadius? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.showGradient = false,
    this.gradientColors,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: showGradient
              ? LinearGradient(
            colors: gradientColors ??
                (isDark
                    ? [
                  AppColors.darkPrimary.withValues(alpha: 0.1),
                  AppColors.darkAccent.withValues(alpha: 0.05),
                ]
                    : [
                  AppColors.lightPrimary.withValues(alpha: 0.08),
                  AppColors.lightAccent.withValues(alpha: 0.04),
                ]),
          )
              : null,
          color: !showGradient
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : null,
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.3)
                : AppColors.lightBorder.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

