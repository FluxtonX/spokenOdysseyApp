import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.logoGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.more_horiz, color: Colors.white, size: 32),
      ),
    );
  }
}
