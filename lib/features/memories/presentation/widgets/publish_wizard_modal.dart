import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubits/memories_cubit.dart';

class PublishWizardModal extends StatefulWidget {
  final String? initialAudioPath;
  final String? initialAlbumId;
  final String initialPrivacy;

  const PublishWizardModal({
    super.key,
    this.initialAudioPath,
    this.initialAlbumId,
    this.initialPrivacy = 'Public',
  });

  @override
  State<PublishWizardModal> createState() => _PublishWizardModalState();
}

class _PublishWizardModalState extends State<PublishWizardModal> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String _memoryType = 'voice';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  late String _privacy;
  String _mood = 'Reflective';
  
  final List<String> _mediaPaths = [];
  String? _selectedAlbumId;
  bool _isPublishing = false;

  final List<String> _moods = [
    'Happy', 'Peaceful', 'Grateful', 'Nostalgic', 'Reflective', 'Proud', 'Sad', 'Excited'
  ];

  @override
  void initState() {
    super.initState();
    _privacy = widget.initialPrivacy;
    _selectedAlbumId = widget.initialAlbumId;
    if (widget.initialAudioPath != null) {
      _mediaPaths.add(widget.initialAudioPath!);
      _memoryType = 'voice';
      // Auto advance past capture if audio provided
      _currentStep = 2;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _mediaPaths.add(picked.path);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<MemoriesCubit>();

    final success = await cubit.createMemory(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      mediaPaths: _mediaPaths,
      privacy: _privacy,
      tags: tags,
      albumId: _selectedAlbumId,
      type: _memoryType,
      mood: _mood,
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (success) {
        nav.pop(true);
        messenger.showSnackBar(
          const SnackBar(content: Text('Memory successfully published!')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to publish memory.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Publish Wizard',
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
          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 2) {
                  _submit();
                } else {
                  setState(() => _currentStep += 1);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              steps: [
                Step(
                  title: const Text('Type'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildTypeSelection(),
                ),
                Step(
                  title: const Text('Capture'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildCaptureContent(),
                ),
                Step(
                  title: const Text('Details'),
                  isActive: _currentStep >= 2,
                  state: _isPublishing ? StepState.editing : StepState.indexed,
                  content: _buildDetailsForm(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What kind of memory would you like to capture?'),
        const SizedBox(height: 16),
        _typeOption('voice', 'Voice Recording', Icons.mic),
        _typeOption('written', 'Written Journal', Icons.edit),
        _typeOption('visual', 'Visual Memory', Icons.image),
        _typeOption('milestone', 'Life Milestone', Icons.emoji_events),
      ],
    );
  }

  Widget _typeOption(String value, String title, IconData icon) {
    final isSelected = _memoryType == value;
    return InkWell(
      onTap: () {
        setState(() => _memoryType = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Icon(icon, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureContent() {
    return Column(
      children: [
        if (_memoryType == 'voice')
          const Text('Voice recording flow will appear here...'),
        if (_memoryType == 'written')
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Start writing your memory...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (_memoryType == 'visual')
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Photo/Video'),
              ),
              const SizedBox(height: 10),
              if (_mediaPaths.isNotEmpty)
                Text('${_mediaPaths.length} file(s) attached'),
            ],
          ),
        if (_memoryType == 'milestone')
          const Text('Milestone selection tools will appear here...'),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title *'),
            validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _mood,
            decoration: const InputDecoration(labelText: 'Mood'),
            items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _mood = val);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _privacy,
            decoration: const InputDecoration(labelText: 'Privacy'),
            items: const [
              DropdownMenuItem(value: 'Public', child: Text('Public')),
              DropdownMenuItem(value: 'Family', child: Text('Family Only')),
              DropdownMenuItem(value: 'Private', child: Text('Private')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _privacy = val);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
          ),
          if (_isPublishing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}
