import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_ui.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class MfaVerificationDialog extends StatefulWidget {
  final String mfaToken;
  final List<String> availableMethods;

  const MfaVerificationDialog({
    super.key,
    required this.mfaToken,
    required this.availableMethods,
  });

  @override
  State<MfaVerificationDialog> createState() => _MfaVerificationDialogState();
}

class _MfaVerificationDialogState extends State<MfaVerificationDialog> {
  late String activeTab;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _recoveryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    activeTab = widget.availableMethods.contains('totp') ? 'totp' : 'recovery';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  void _verifyTotp() {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    context.read<AuthCubit>().verifyTotpMfa(
      mfaToken: widget.mfaToken,
      code: code,
    );
  }

  void _verifyRecovery() {
    final code = _recoveryController.text.trim();
    if (code.length < 8) return;
    context.read<AuthCubit>().verifyRecoveryMfa(
      mfaToken: widget.mfaToken,
      code: code,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pop(true);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: AppIconButton(
                    icon: Icons.close,
                    label: 'Close verification',
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const Icon(Icons.security, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please verify your secondary factor to complete sign-in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                // Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.availableMethods.contains('totp'))
                      _buildTab('TOTP', 'totp'),
                    _buildTab('Recovery', 'recovery'),
                  ],
                ),
                const SizedBox(height: 24),
                // Content
                if (activeTab == 'totp')
                  _buildTotpForm(isLoading)
                else if (activeTab == 'passkey')
                  _buildPasskeyForm(isLoading)
                else
                  _buildRecoveryForm(isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    final isActive = activeTab == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label verification method',
        child: InkWell(
          onTap: () {
            setState(() {
              activeTab = value;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.textWhite : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotpForm(bool isLoading) {
    return Column(
      children: [
        const Text(
          '6-Digit Authenticator Code',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.blue[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyTotp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verify & Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasskeyForm(bool isLoading) {
    return Column(
      children: [
        const Text(
          'Use Touch ID, Face ID, or a hardware security key to confirm your identity.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Authenticate with Passkey',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryForm(bool isLoading) {
    return Column(
      children: [
        const Text(
          'One-Time Emergency Recovery Code',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _recoveryController,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'XXXX-XXXX',
            filled: true,
            fillColor: Colors.blue[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyRecovery,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Use Recovery Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
