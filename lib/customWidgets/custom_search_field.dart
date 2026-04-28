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
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final hintColor =
        theme.textTheme.bodySmall?.color ?? AppTheme.adaptiveTextHint;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.outfit(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: hintColor),
              prefixIcon: Icon(Icons.search, color: hintColor, size: 20),
              border: InputBorder.none,

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(color: AppTheme.adaptiveBorder),
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
            color: AppTheme.adaptiveCardBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.adaptiveBorder),
          ),
          child: IconButton(
            icon: Icon(Icons.filter_alt_outlined, color: textColor, size: 20),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
