import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme.dart';

class CustomSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;

  const CustomSearchField({
    super.key,
    this.hintText = 'Search by name, profes...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textHint,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              border: InputBorder.none,

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(color: AppTheme.floatingActionButton),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.filter_alt_outlined,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
