import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please accept Terms of Use and Privacy Policy to continue.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              Navigator.pushReplacementNamed(context, '/home');
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
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AssetConstants.logo,
                          height: 36,
                          width: 36,
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Spoken Odyssey',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Create your account',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        hintText: 'Confirm password',
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _agreeToTerms = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'I have read and agree to our Terms of Use and Privacy Policy',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isLoading ? null : _onSignUpPressed,
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have account? ',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.borderLight),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.borderLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().googleSignIn();
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="22" height="22"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/></svg>''',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().appleSignIn();
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170" width="22" height="22" fill="#000000"><path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.87.13-9.74-1.92-14.62-6.14-3.35-2.88-7.23-7.61-11.64-14.19-7.41-11.02-13.11-23.47-17.1-37.35-3.99-13.88-5.99-27.12-5.99-39.72 0-14.88 3.56-27.32 10.68-37.33 7.12-10.01 16.27-15.14 27.46-15.39 5.34 0 10.99 1.25 16.94 3.76 5.95 2.51 10.02 3.86 12.22 4.05 1.83-.19 5.99-1.57 12.48-4.14 6.49-2.57 11.96-3.76 16.41-3.57 11.89.5 21.6 4.7 29.13 12.6-10.39 6.26-15.46 15.02-15.21 26.28.25 8.76 3.69 16.03 10.31 21.8 6.63 5.77 14.54 9.07 23.74 9.9-2.52 7.52-5.9 15.22-10.14 23.11zM119.22 31.9c0-6.77 2.47-13.2 7.41-19.29 4.94-6.09 11.07-9.74 18.39-10.95.12.87.18 1.62.18 2.25 0 6.64-2.54 13.06-7.62 19.26-5.08 6.2-11.23 9.87-18.46 11.01-.12-.75-.18-1.52-.18-2.28z"/></svg>''',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Apple',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
