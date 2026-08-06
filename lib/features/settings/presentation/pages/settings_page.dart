import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubits/settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _legacyEnabled = false;
  String _inactivityPeriod = '6_months';
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (context) => sl<SettingsCubit>()..loadSettings(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Settings & Legacy Access',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: BlocConsumer<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded) {
              setState(() {
                _legacyEnabled = state.legacySettings.isEnabled;
                _inactivityPeriod = state.legacySettings.inactivityPeriod;
                _noteController.text = state.legacySettings.note ?? '';
              });
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legacy Access Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(
                                  'Digital Legacy Access',
                                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Switch(
                              value: _legacyEnabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() => _legacyEnabled = val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Automatically grant designated family members access to your voice memories after a period of account inactivity.',
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (_legacyEnabled) ...[
                          const SizedBox(height: 16),
                          Text('Inactivity Duration', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _inactivityPeriod,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: '3_months', child: Text('3 Months Inactivity')),
                              DropdownMenuItem(value: '6_months', child: Text('6 Months Inactivity')),
                              DropdownMenuItem(value: '1_year', child: Text('1 Year Inactivity')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _inactivityPeriod = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text('Legacy Note for Family', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'A message for your legacy contact...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<SettingsCubit>().updateLegacySettings(
                                      isEnabled: _legacyEnabled,
                                      inactivityPeriod: _inactivityPeriod,
                                      note: _noteController.text.trim(),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Legacy settings updated!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: Text('Save Legacy Settings', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Actions Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Settings', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                          title: Text('Sign Out', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          onTap: () {
                            context.read<AuthCubit>().signOut();
                            Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
