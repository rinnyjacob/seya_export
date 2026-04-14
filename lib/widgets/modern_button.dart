import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final bool isOutlined;
  final double height;
  final double width;
  final IconData? icon;

  const ModernButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.isOutlined = false,
    this.height = 56,
    this.width = double.infinity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (isOutlined) {
      return SizedBox(
        height: height,
        width: width,
        child: OutlinedButton(
          onPressed: isEnabled && !isLoading ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isEnabled ? primaryColor : AppColors.lightBorder,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            disabledForegroundColor: AppColors.lightTextSecondary.withValues(alpha: 0.5),
          ),
          child: _buildContent(primaryColor, isDark),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lightBorder,
          disabledForegroundColor: AppColors.lightTextSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),
        child: _buildContent(primaryColor, isDark),
      ),
    );
  }

  Widget _buildContent(Color primaryColor, bool isDark) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? primaryColor : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}

