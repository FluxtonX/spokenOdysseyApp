import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubits/family_cubit.dart';

class CategorizedRelationship {
  final String category;
  final List<String> options;

  const CategorizedRelationship({
    required this.category,
    required this.options,
  });
}

class CountryCodeOption {
  final String name;
  final String dialCode;
  final String flag;

  const CountryCodeOption({
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

const List<CategorizedRelationship> categorizedRelationships = [
  CategorizedRelationship(
    category: 'Primary Relations',
    options: [
      'Spouse/Partner',
      'Child',
      'Parent',
      'Sibling',
      'Grandparent',
      'Grandchild',
      'Aunt/Uncle',
      'Niece/Nephew',
      'Cousin',
      'Friend',
      'Other',
    ],
  ),
  CategorizedRelationship(
    category: 'Immediate Family',
    options: [
      'Mother',
      'Father',
      'Sister',
      'Brother',
      'Daughter',
      'Son',
      'Wife',
      'Husband',
      'Partner',
    ],
  ),
  CategorizedRelationship(
    category: 'Uncles & Aunts',
    options: [
      'Maternal Uncle (Mamoo)',
      'Paternal Uncle (Chacha)',
      'Maternal Aunt (Khala)',
      'Paternal Aunt (Phuppho)',
      'Uncle',
      'Aunty',
    ],
  ),
  CategorizedRelationship(
    category: 'Grandparents & Relatives',
    options: [
      'Grandmother (Dadi / Nani)',
      'Grandfather (Dada / Nana)',
      'Grandson',
      'Granddaughter',
      'Cousin',
      'Nephew',
      'Niece',
    ],
  ),
  CategorizedRelationship(
    category: 'In-Laws & Step Relations',
    options: [
      'Stepfather',
      'Stepmother',
      'Stepbrother',
      'Stepsister',
      'Mother-in-law',
      'Father-in-law',
      'Brother-in-law',
      'Sister-in-law',
      'Guardian / Relative',
    ],
  ),
];

const List<CountryCodeOption> countryCodes = [
  CountryCodeOption(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  CountryCodeOption(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  CountryCodeOption(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  CountryCodeOption(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  CountryCodeOption(
    name: 'United Arab Emirates',
    dialCode: '+971',
    flag: '🇦🇪',
  ),
  CountryCodeOption(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  CountryCodeOption(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  CountryCodeOption(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  CountryCodeOption(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
];

class InviteMemberModal extends StatefulWidget {
  const InviteMemberModal({super.key});

  @override
  State<InviteMemberModal> createState() => _InviteMemberModalState();
}

class _InviteMemberModalState extends State<InviteMemberModal> {
  int _step = 1; // 1: Menu, 2: Email, 3: QR, 4: SMS, 5: Success, 6: Link
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _relationship = 'Parent';
  CountryCodeOption _selectedCountry = countryCodes[0];
  String? _generatedLink;
  String? _qrCodeUrl;
  bool _isSubmitting = false;
  String _sentRecipient = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step != 1 && _step != 5)
                    GestureDetector(
                      onTap: () => setState(() => _step = 1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      _step == 5
                          ? 'Invitation Sent!'
                          : 'Invite to Family Circle',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Step Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case 1:
        return _buildMenuOptions();
      case 2:
        return _buildEmailStep();
      case 3:
        return _buildQrStep();
      case 4:
        return _buildSmsStep();
      case 5:
        return _buildSuccessStep();
      case 6:
        return _buildLinkStep();
      default:
        return _buildMenuOptions();
    }
  }

  // STEP 1: Main Menu 2x2 Grid Options exactly matching Web
  Widget _buildMenuOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _buildOptionCard(
              icon: Icons.mail_outline_rounded,
              title: 'Email Invitation',
              subtitle: 'Send a personal email invite',
              onTap: () => setState(() => _step = 2),
            ),
            _buildOptionCard(
              icon: Icons.phone_outlined,
              title: 'SMS / Phone',
              subtitle: 'Text them an invite link',
              onTap: () => setState(() => _step = 4),
            ),
            _buildOptionCard(
              icon: Icons.link_rounded,
              title: 'Share a Link',
              subtitle: 'Copy and share anywhere',
              onTap: () => setState(() => _step = 6),
            ),
            _buildOptionCard(
              icon: Icons.qr_code_rounded,
              title: 'QR Code',
              subtitle: 'Show a scannable code',
              onTap: () => setState(() => _step = 3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF4A3AFF), size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2: Invite by Email
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite by Email',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Text(
          'Their name',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "e.g. Sarah O'Brien",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Email address',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'their@email.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Relationship',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildRelationshipDropdown(),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSendEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A3AFF),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Send Invitation',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  void _handleSendEmail() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSubmitting = true);
    final cubit = context.read<FamilyCubit>();
    await cubit.sendEmailInvite(
      email,
      _relationship,
      name: name.isNotEmpty ? name : null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _sentRecipient = name.isNotEmpty ? name : email;
        _step = 5;
      });
    }
  }

  // STEP 4: SMS Invitation
  Widget _buildSmsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite via SMS',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Text(
          'Country',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CountryCodeOption>(
              isExpanded: true,
              value: _selectedCountry,
              items: countryCodes.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        c.dialCode,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCountry = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Phone Number',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                _selectedCountry.dialCode,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '555 000 0000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text(
          'Relationship',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildRelationshipDropdown(),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSendSms,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A3AFF),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Send SMS Invite',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  void _handleSendSms() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    final fullPhone = '${_selectedCountry.dialCode}$phone';
    setState(() => _isSubmitting = true);
    final cubit = context.read<FamilyCubit>();
    await cubit.sendSMSInvite(fullPhone, _relationship);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _sentRecipient = fullPhone;
        _step = 5;
      });
    }
  }

  // STEP 6: Share a Link
  Widget _buildLinkStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share a Link',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Generate a secure link to share with your family member.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Relationship',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildRelationshipDropdown(),
        const SizedBox(height: 20),

        if (_generatedLink != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _generatedLink!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A3AFF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF4A3AFF),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedLink!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleGenerateLink,
          icon: const Icon(Icons.link_rounded, color: Colors.white),
          label: Text(
            _generatedLink != null
                ? 'Link Copied! Generate New'
                : 'Generate & Copy Link',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A3AFF),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleGenerateLink() async {
    setState(() => _isSubmitting = true);
    final invite = await context.read<FamilyCubit>().createLinkInvite(
      _relationship,
    );
    if (mounted) {
      final link =
          invite?.inviteUrl ??
          'https://spokenodyssey.app/invite/${invite?.invitationToken ?? "family"}';
      Clipboard.setData(ClipboardData(text: link));
      setState(() {
        _isSubmitting = false;
        _generatedLink = link;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard!')),
      );
    }
  }

  // STEP 3: QR Code
  Widget _buildQrStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan QR Code',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Select relationship and generate a QR code for your family member to scan.',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Relationship',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildRelationshipDropdown(),
        const SizedBox(height: 20),

        if (_qrCodeUrl != null) ...[
          Center(
            child: Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Image.network(_qrCodeUrl!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),
        ],

        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleGenerateQr,
          icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
          label: Text(
            _qrCodeUrl != null ? 'Regenerate QR Code' : 'Generate QR Code',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A3AFF),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleGenerateQr() async {
    setState(() => _isSubmitting = true);
    final invite = await context.read<FamilyCubit>().createQRInvite(
      _relationship,
    );
    if (mounted) {
      final link =
          invite?.inviteUrl ??
          'https://spokenodyssey.app/invite/${invite?.invitationToken ?? "qr"}';
      final qrApi =
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(link)}';
      setState(() {
        _isSubmitting = false;
        _qrCodeUrl = qrApi;
      });
    }
  }

  // STEP 5: "Invitation Sent!" Success State Modal exactly matching Web
  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFD1FAE5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF10B981),
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Invitation Sent!',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_sentRecipient.isNotEmpty ? _sentRecipient : "Recipient"} will receive an invitation and can join your Family Circle.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // "What happens next?" Box matching Web UI
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E4FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What happens next?',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A3AFF),
                ),
              ),
              const SizedBox(height: 12),
              _buildStepRow('1', 'They receive your invitation'),
              const SizedBox(height: 8),
              _buildStepRow('2', 'They create or sign in to their account'),
              const SizedBox(height: 8),
              _buildStepRow('3', 'They confirm the relationship'),
              const SizedBox(height: 8),
              _buildStepRow('4', 'They join your Family Circle'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: () {
            context.read<FamilyCubit>().loadFamilyCircle();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A3AFF),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Done',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF4A3AFF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Relationship dropdown with categorized choices
  Widget _buildRelationshipDropdown() {
    final List<DropdownMenuItem<String>> items = [];

    for (final cat in categorizedRelationships) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: 'cat_${cat.category}',
          child: Text(
            cat.category.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A3AFF),
              letterSpacing: 0.8,
            ),
          ),
        ),
      );

      for (final option in cat.options) {
        items.add(
          DropdownMenuItem<String>(
            value: option,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                option,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _relationship,
          items: items,
          onChanged: (val) {
            if (val != null && !val.startsWith('cat_')) {
              setState(() => _relationship = val);
            }
          },
        ),
      ),
    );
  }
}
