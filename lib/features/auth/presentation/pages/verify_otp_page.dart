import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;

  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 59;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyCode() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      context.read<AuthCubit>().verifyOtp(email: widget.email, otp: otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is OtpVerified) {
              Navigator.pushNamed(
                context,
                '/reset-password',
                arguments: {'email': state.email, 'otp': state.otp},
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter verification code',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "The verification code has been sent to your email\n${widget.email}",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // 6 digit PIN row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => SizedBox(
                        width: 48,
                        height: 54,
                        child: TextFormField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.borderLight,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                          onChanged: (val) => _onOtpChanged(index, val),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Not received yet? ',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      _secondsRemaining > 0
                          ? Text(
                              'Resend after $_secondsRemaining seconds',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppColors.textLight,
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                _startTimer();
                                context.read<AuthCubit>().forgotPassword(
                                  widget.email,
                                );
                              },
                              child: Text(
                                'Resend Code',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: isLoading ? null : _verifyCode,
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Verify & Continue'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
