import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

/// iOS only: shown during an import when the iPhone can't switch from its own Wi‑Fi to the
/// glasses' hotspot (iOS refuses the switch from some networks, e.g. 5 GHz ones, and apps
/// aren't allowed to disconnect the phone). The import waits here and continues by itself as
/// soon as the user disconnects.
class GlassesWifiDisconnectCard extends StatelessWidget {
  final VoidCallback onStop;

  const GlassesWifiDisconnectCard({super.key, required this.onStop});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disconnect from Wi‑Fi to continue',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your iPhone can\'t switch from this Wi‑Fi to your glasses on its own.',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _Step(
            number: 1,
            text: 'Swipe down from the top‑right corner to open Control Center.',
          ),
          const SizedBox(height: 8),
          const _Step(
            number: 2,
            text: 'Tap the Wi‑Fi icon once so it turns grey. Wi‑Fi stays on.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep this screen open — the import continues by itself.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onStop,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Stop',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
