import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubits/settings_cubit.dart';
import 'package:flutter/services.dart';

class MfaSetupModal extends StatefulWidget {
  const MfaSetupModal({super.key});

  @override
  State<MfaSetupModal> createState() => _MfaSetupModalState();
}

class _MfaSetupModalState extends State<MfaSetupModal> {
  int _currentStep = 0;
  bool _isLoading = true;
  String? _error;

  String? _secret;
  String? _qrCodeDataUrl;

  final _codeController = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initMfa();
  }

  Future<void> _initMfa() async {
    final cubit = context.read<SettingsCubit>();
    final data = await cubit.setupMfa();
    if (mounted) {
      if (data != null) {
        setState(() {
          _secret = data['secret'];
          _qrCodeDataUrl = data['qrCodeDataUrl'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to initialize MFA setup.";
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildQrCode() {
    if (_qrCodeDataUrl == null) return const SizedBox();

    // Extract base64 part from "data:image/png;base64,..."
    final parts = _qrCodeDataUrl!.split(',');
    if (parts.length == 2) {
      final base64Str = parts[1];
      try {
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, width: 200, height: 200);
      } catch (e) {
        return const Text("Failed to render QR Code");
      }
    }
    return const SizedBox();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit code.")),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final cubit = context.read<SettingsCubit>();
    final success = await cubit.verifyMfaSetup(code);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
      if (success) {
        setState(() {
          _currentStep = 2; // Move to success step
        });
        // We also need to reload settings or tell the parent MFA is active
        cubit.loadSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid verification code. Try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Setup Two-Factor Auth',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          else
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                controlsBuilder: (context, details) {
                  return const SizedBox(); // Custom controls in step content
                },
                steps: [
                  Step(
                    title: const Text('Scan'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildScanStep(),
                  ),
                  Step(
                    title: const Text('Verify'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildVerifyStep(),
                  ),
                  Step(
                    title: const Text('Done'),
                    isActive: _currentStep >= 2,
                    state: StepState.complete,
                    content: _buildDoneStep(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanStep() {
    return Column(
      children: [
        const Text(
          "1. Open your authenticator app (like Google Authenticator or Authy).",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text("2. Scan the QR code below:", textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _buildQrCode(),
        ),
        const SizedBox(height: 20),
        Text(
          "Or enter this secret manually:",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Text(
                  _secret ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (_secret != null) {
                    Clipboard.setData(ClipboardData(text: _secret!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Secret copied to clipboard"),
                      ),
                    );
                  }
                },
                child: const Icon(
                  Icons.copy,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next Step',
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

  Widget _buildVerifyStep() {
    return Column(
      children: [
        const Text(
          "Enter the 6-digit code generated by your authenticator app to verify the setup.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
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
            hintText: "000000",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isVerifying
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 0;
                        });
                      },
                child: const Text("Back"),
              ),
            ),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify & Enable',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        const SizedBox(height: 20),
        const Text(
          "MFA has been successfully enabled!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Your account is now protected with Two-Factor Authentication. Note: You should securely save your recovery codes.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Done',
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
