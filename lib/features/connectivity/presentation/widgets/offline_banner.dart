import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../cubit/connectivity_cubit.dart';

/// Shows a slim "You're offline" strip above [child] (the whole app) while
/// there is no internet, and hides it as soon as the connection is back.
class OfflineBannerLayout extends StatelessWidget {
  final Widget child;

  const OfflineBannerLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        final offline = !state.isOnline;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: offline
                  ? const OfflineBanner()
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(
              // While shown, the banner covers the status bar area, so the
              // screens below must not add that space again.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: offline,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const String message = "You're offline";
  static const String detail = 'Check your internet connection';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: AppColors.textPrimary,
        child: SafeArea(
          bottom: false,
          child: Semantics(
            liveRegion: true,
            label: '$message. $detail.',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceLg,
                  vertical: DesignTokens.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: message,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textWhite,
                              ),
                            ),
                            TextSpan(
                              text: '  ·  $detail',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textWhite.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
