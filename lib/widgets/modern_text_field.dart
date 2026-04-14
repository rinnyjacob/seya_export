import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> with TickerProviderStateMixin {
  late bool _obscureText;
  late FocusNode _focusNode;
  late AnimationController _eyeController;
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = FocusNode();

    _eyeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _eyeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    if (widget.obscureText) {
      setState(() => _obscureText = !_obscureText);
      if (_obscureText) {
        _eyeController.reverse();
        _colorController.reverse();
      } else {
        _eyeController.forward();
        _colorController.forward();
      }
    }
    widget.onSuffixTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return IgnorePointer(
      ignoring: widget.readOnly,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {});
        },
        child: TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          readOnly: widget.readOnly,
          keyboardType: widget.keyboardType,
          maxLines: _obscureText ? 1 : widget.maxLines,
          focusNode: _focusNode,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon)
                : null,
            suffixIcon: widget.suffixIcon != null
                ? GestureDetector(
                    onTap: _togglePasswordVisibility,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                        CurvedAnimation(parent: _eyeController, curve: Curves.elasticOut),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          widget.suffixIcon,
                          color: _obscureText
                              ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                              : primaryColor,
                        ),
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.lightDivider,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: _focusNode.hasFocus
                  ? BorderSide(
                      color: primaryColor,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkError : AppColors.lightError,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkError : AppColors.lightError,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

