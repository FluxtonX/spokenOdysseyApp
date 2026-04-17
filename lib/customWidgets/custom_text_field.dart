import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';

/// A highly reusable text field that adapts to the app theme.
///
/// Supports labels, hints, prefix/suffix icons, password toggle,
/// validation, keyboard types, and input formatters.
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffix;
  final Widget? prefix;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final String? errorText;
  final Widget? labelTrailing;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onTap,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
    this.errorText,
    this.labelTrailing,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label row ──
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (widget.labelTrailing != null) widget.labelTrailing!,
            ],
          ),
          const SizedBox(height: 8),
        ],

        // ── Text field ──
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.outfit(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
            errorText: widget.errorText,
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            prefixIcon:
                widget.prefix ??
                (widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: AppTheme.textSecondary,
                        size: 24,
                      )
                    : null),
            suffixIcon: widget.suffix ?? _buildSuffix(theme),
          ),
        ),
      ],
    );
  }

  /// Builds the appropriate suffix widget:
  /// - Password toggle if [isPassword]
  /// - Custom suffixIcon if provided
  /// - null otherwise
  Widget? _buildSuffix(ThemeData theme) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppTheme.textSecondary,
          size: 24,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    if (widget.suffixIcon != null) {
      return Icon(widget.suffixIcon, color: AppTheme.textSecondary, size: 24);
    }
    return null;
  }
}
