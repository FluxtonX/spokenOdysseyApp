import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../services/album_service.dart';
import '../../services/memory_service.dart';
import '../../theme/theme.dart';
import '../../utils/image_picker_helper.dart';
import 'memory_detail_screen.dart';

enum RecordStoryFormat { voice, text, photoText, video }

extension RecordStoryFormatX on RecordStoryFormat {
  String get label => switch (this) {
    RecordStoryFormat.voice => 'Voice',
    RecordStoryFormat.text => 'Text',
    RecordStoryFormat.photoText => 'Photo + Text',
    RecordStoryFormat.video => 'Video',
  };

  String get description => switch (this) {
    RecordStoryFormat.voice =>
      'Speak naturally and save the feeling while it is still present.',
    RecordStoryFormat.text =>
      'Write the memory carefully when words are the clearest format.',
    RecordStoryFormat.photoText =>
      'Pair an image with context so the memory keeps its meaning.',
    RecordStoryFormat.video =>
      'Capture expression, movement, and voice together.',
  };

  String get mediaLabel => switch (this) {
    RecordStoryFormat.voice => 'Audio clip',
    RecordStoryFormat.text => 'Written memory',
    RecordStoryFormat.photoText => 'Photo memory',
    RecordStoryFormat.video => 'Video clip',
  };

  IconData get icon => switch (this) {
    RecordStoryFormat.voice => Icons.mic_none_rounded,
    RecordStoryFormat.text => Icons.edit_note_rounded,
    RecordStoryFormat.photoText => Icons.collections_outlined,
    RecordStoryFormat.video => Icons.videocam_outlined,
  };

  Color get accent => switch (this) {
    RecordStoryFormat.voice => const Color(0xFF5544FF),
    RecordStoryFormat.text => const Color(0xFF5ABA82),
    RecordStoryFormat.photoText => const Color(0xFFE2923A),
    RecordStoryFormat.video => const Color(0xFFE85D75),
  };
}

class RecordStoryScreen extends StatefulWidget {
  const RecordStoryScreen({
    super.key,
    this.initialFormat,
    this.initialDraft,
    this.initialAlbumId,
  });

  final RecordStoryFormat? initialFormat;
  final Map<String, dynamic>? initialDraft;
  final String? initialAlbumId;

  @override
  State<RecordStoryScreen> createState() => _RecordStoryScreenState();
}

class _RecordStoryScreenState extends State<RecordStoryScreen> {
  final AlbumService _albumService = AlbumService();
  final MemoryService _memoryService = MemoryService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _storyFocusNode = FocusNode();
  final FocusNode _tagsFocusNode = FocusNode();

  final List<String> _moods = const [
    'Reflective',
    'Grateful',
    'Proud',
    'Tender',
    'Playful',
    'Hopeful',
  ];
  final List<String> _privacyOptions = const ['Private', 'Family', 'Public'];
  final List<String> _stepTitles = const [
    'Format',
    'Memory',
    'Context',
    'Review',
  ];

  RecordStoryFormat? _selectedFormat;
  String _selectedMood = 'Reflective';
  String _selectedPrivacy = 'Private';
  DateTime _selectedDate = DateTime.now();
  String? _selectedAlbumId;

  bool _isLoadingAlbums = true;
  bool _isRecording = false;
  bool _isSaving = false;
  int _currentStep = 0;

  List<Map<String, dynamic>> _albums = [];
  File? _photoFile;
  File? _videoFile;
  String? _audioPath;
  Duration _audioDuration = Duration.zero;
  Timer? _recordingTimer;
  Map<String, dynamic>? _savedResult;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat ?? _resolveDraftFormat();
    _selectedAlbumId = widget.initialAlbumId;
    _hydrateDraft();
    _currentStep = _selectedFormat == null ? 0 : 1;
    _loadAlbums();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _titleController.dispose();
    _storyController.dispose();
    _tagsController.dispose();
    _titleFocusNode.dispose();
    _storyFocusNode.dispose();
    _tagsFocusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  RecordStoryFormat? _resolveDraftFormat() {
    final type = widget.initialDraft?['type']?.toString().toLowerCase() ?? '';
    if (type.contains('voice')) return RecordStoryFormat.voice;
    if (type.contains('photo')) return RecordStoryFormat.photoText;
    if (type.contains('video')) return RecordStoryFormat.video;
    if (type.contains('text')) return RecordStoryFormat.text;
    return null;
  }

  void _hydrateDraft() {
    final draft = widget.initialDraft;
    if (draft == null) {
      return;
    }

    _titleController.text = draft['title']?.toString() ?? '';
    _storyController.text =
        draft['description']?.toString() ?? draft['summary']?.toString() ?? '';
    final tags = draft['tags'];
    if (tags is List) {
      _tagsController.text = tags.join(', ');
    }

    final privacy = draft['privacy']?.toString();
    if (privacy != null && _privacyOptions.contains(privacy)) {
      _selectedPrivacy = privacy;
    }

    final mood = draft['mood']?.toString();
    if (mood != null && _moods.contains(mood)) {
      _selectedMood = mood;
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await _albumService.fetchAlbums();
      if (!mounted) return;

      setState(() {
        _albums = albums;
        _selectedAlbumId =
            (_selectedAlbumId != null &&
                albums.any(
                  (album) => album['id']?.toString() == _selectedAlbumId,
                ))
            ? _selectedAlbumId
            : albums.isNotEmpty
            ? albums.first['id']?.toString()
            : null;
        _isLoadingAlbums = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _albums = const [];
        _selectedAlbumId = null;
        _isLoadingAlbums = false;
      });
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      await _stopVoiceRecording();
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      Get.snackbar(
        'Microphone access needed',
        'Please allow microphone access to record a voice memory.',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/story_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _audioDuration += const Duration(seconds: 1);
      });
    });

    setState(() {
      _audioPath = null;
      _audioDuration = Duration.zero;
      _isRecording = true;
    });
  }

  Future<void> _stopVoiceRecording() async {
    final path = await _audioRecorder.stop();
    _recordingTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _audioPath = path;
      _isRecording = false;
    });
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePickerHelper.pickWithSourceSheet(context);
    if (file == null || !mounted) return;

    setState(() {
      _photoFile = file;
    });
  }

  Future<void> _pickVideo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.adaptiveCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.adaptiveDivider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSourceActionTile(
                  icon: Icons.videocam_outlined,
                  title: 'Record video',
                  subtitle: 'Capture a new moment right now.',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                _buildSourceActionTile(
                  icon: Icons.video_library_outlined,
                  title: 'Choose from library',
                  subtitle: 'Select an existing clip from your device.',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final allowed = source == ImageSource.camera
        ? await Permission.camera.request().isGranted
        : await _requestGalleryAccess();
    if (!allowed) return;

    final picked = await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _videoFile = File(picked.path);
    });
  }

  Future<bool> _requestGalleryAccess() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) {
      return true;
    }

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  bool get _canAdvance {
    switch (_currentStep) {
      case 0:
        return _selectedFormat != null;
      case 1:
        final titleFilled = _titleController.text.trim().isNotEmpty;
        final storyFilled = _storyController.text.trim().isNotEmpty;
        switch (_selectedFormat) {
          case RecordStoryFormat.voice:
            return titleFilled && (_audioPath != null || storyFilled);
          case RecordStoryFormat.text:
            return titleFilled && storyFilled;
          case RecordStoryFormat.photoText:
            return titleFilled && storyFilled && _photoFile != null;
          case RecordStoryFormat.video:
            return titleFilled && _videoFile != null;
          case null:
            return false;
        }
      case 2:
        return _selectedPrivacy.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _submitStory({required bool publish}) async {
    setState(() {
      _isSaving = true;
    });

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final selectedAlbum = _albums.cast<Map<String, dynamic>?>().firstWhere(
      (album) => album?['id']?.toString() == _selectedAlbumId,
      orElse: () => null,
    );
    final format = _selectedFormat!;
    final mediaFile = switch (format) {
      RecordStoryFormat.voice => _audioPath != null ? File(_audioPath!) : null,
      RecordStoryFormat.text => null,
      RecordStoryFormat.photoText => _photoFile,
      RecordStoryFormat.video => _videoFile,
    };

    try {
      final memory = await _memoryService.createMemory(
        title: _titleController.text.trim(),
        description: _storyController.text.trim(),
        tags: tags,
        mood: _selectedMood,
        privacy: _selectedPrivacy,
        type: format.label,
        publish: publish,
        occurredAt: _selectedDate,
        albumId: _selectedAlbumId,
        mediaFile: mediaFile,
      );

      if (!mounted) return;

      final result = {
        'memory': {
          ...memory,
          'albumTitle':
              memory['albumTitle'] ?? selectedAlbum?['title']?.toString(),
        },
        'status': publish ? 'published' : 'draft',
      };

      setState(() {
        _savedResult = result;
        _isSaving = false;
        _currentStep = 4;
      });

      final uploadWarning = memory['coverUploadWarning']?.toString();
      if (uploadWarning != null && uploadWarning.isNotEmpty) {
        Get.snackbar(
          'Memory saved with note',
          uploadWarning,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      Get.snackbar(
        'Could not save memory',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _goNext() {
    FocusScope.of(context).unfocus();
    if (!_canAdvance || _currentStep >= 3) return;
    setState(() {
      _currentStep += 1;
    });
  }

  void _goBack() {
    if (_currentStep == 0) {
      Get.back();
      return;
    }

    setState(() {
      _currentStep -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final format = _selectedFormat;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'New Memory',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _currentStep == 4
                      ? _buildConfirmationStep()
                      : Column(
                          key: ValueKey<int>(_currentStep),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_currentStep == 0) _buildFormatStep(),
                            if (_currentStep == 1 && format != null)
                              _buildStoryStep(format),
                            if (_currentStep == 2 && format != null)
                              _buildContextStep(format),
                            if (_currentStep == 3 && format != null)
                              _buildReviewStep(format),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final totalSteps = _stepTitles.length;
    final activeIndex = _currentStep.clamp(0, totalSteps - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentStep == 4
              ? 'Memory ready'
              : 'Step ${activeIndex + 1} of $totalSteps',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5544FF),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= activeIndex;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF5544FF)
                      : AppTheme.adaptiveDivider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFormatStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose the format that matches this moment.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change this later, but starting with the right shape keeps the memory flowing.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.6,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
        const SizedBox(height: 18),
        ...RecordStoryFormat.values.map(_buildFormatCard),
      ],
    );
  }

  Widget _buildStoryStep(RecordStoryFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Shape the memory'),
        const SizedBox(height: 8),
        _buildFormatSummary(format),
        const SizedBox(height: 18),
        _buildFieldLabel('Title'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          onChanged: (_) => setState(() {}),
          onTapOutside: (_) => _dismissKeyboard(),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_storyFocusNode),
          decoration: const InputDecoration(
            hintText: 'Give this memory a clear, human title',
          ),
        ),
        const SizedBox(height: 16),
        if (format == RecordStoryFormat.voice) _buildVoiceComposer(),
        if (format == RecordStoryFormat.text) _buildTextComposer(),
        if (format == RecordStoryFormat.photoText) _buildPhotoComposer(),
        if (format == RecordStoryFormat.video) _buildVideoComposer(),
      ],
    );
  }

  Widget _buildContextStep(RecordStoryFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Add context and access'),
        const SizedBox(height: 8),
        Text(
          'This is where the memory becomes findable, emotionally rich, and ready for the right audience.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.6,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Mood'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _moods.map((mood) {
            final selected = mood == _selectedMood;
            return ChoiceChip(
              label: Text(mood),
              selected: selected,
              onSelected: (_) => setState(() => _selectedMood = mood),
              selectedColor: format.accent.withValues(alpha: 0.16),
              backgroundColor: AppTheme.adaptiveSoftSurface,
              side: BorderSide(
                color: selected
                    ? format.accent.withValues(alpha: 0.36)
                    : AppTheme.adaptiveBorder,
              ),
              labelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: selected
                    ? format.accent
                    : AppTheme.adaptiveTextSecondary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Tags'),
        const SizedBox(height: 8),
        TextField(
          controller: _tagsController,
          focusNode: _tagsFocusNode,
          onTapOutside: (_) => _dismissKeyboard(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _dismissKeyboard(),
          decoration: const InputDecoration(
            hintText: 'family, courage, school, turning point',
          ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Memory date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.adaptiveCardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.adaptiveBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.adaptiveTextSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM d, y').format(_selectedDate),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Privacy'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _privacyOptions.map((option) {
            final selected = option == _selectedPrivacy;
            return ChoiceChip(
              label: Text(option),
              selected: selected,
              onSelected: (_) => setState(() => _selectedPrivacy = option),
              selectedColor: format.accent.withValues(alpha: 0.16),
              backgroundColor: AppTheme.adaptiveSoftSurface,
              side: BorderSide(
                color: selected
                    ? format.accent.withValues(alpha: 0.36)
                    : AppTheme.adaptiveBorder,
              ),
              labelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: selected
                    ? format.accent
                    : AppTheme.adaptiveTextSecondary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Album'),
        const SizedBox(height: 8),
        _buildAlbumPicker(),
      ],
    );
  }

  Widget _buildReviewStep(RecordStoryFormat format) {
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final selectedAlbum = _albums.cast<Map<String, dynamic>?>().firstWhere(
      (album) => album?['id']?.toString() == _selectedAlbumId,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Review before saving'),
        const SizedBox(height: 8),
        Text(
          'Check the essentials, then choose whether this stays a draft or becomes part of your archive now.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.6,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
        const SizedBox(height: 18),
        _buildReviewCard(
          title: _titleController.text.trim(),
          subtitle: format.label,
          body: _storyController.text.trim().isEmpty
              ? 'No written reflection added.'
              : _storyController.text.trim(),
        ),
        const SizedBox(height: 14),
        _buildReviewMediaPreview(format),
        const SizedBox(height: 14),
        _buildReviewMetaRow('Mood', _selectedMood),
        _buildReviewMetaRow(
          'Date',
          DateFormat('MMMM d, y').format(_selectedDate),
        ),
        _buildReviewMetaRow('Privacy', _selectedPrivacy),
        _buildReviewMetaRow(
          'Album',
          selectedAlbum?['title']?.toString() ?? 'No album selected yet',
        ),
        if (tags.isNotEmpty) _buildReviewMetaRow('Tags', tags.join(', ')),
      ],
    );
  }

  Widget _buildReviewMediaPreview(RecordStoryFormat format) {
    final accent = format.accent;

    Widget content;
    switch (format) {
      case RecordStoryFormat.voice:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5544FF), Color(0xFF3B2BC7), Color(0xFF1D2140)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _audioPath != null
                              ? 'Voice clip attached'
                              : 'Voice format selected',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _audioPath != null
                              ? 'Duration: ${_formatDuration(_audioDuration)}'
                              : 'No audio clip attached yet.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(12, (index) {
                  final heights = [
                    14.0,
                    22.0,
                    28.0,
                    20.0,
                    34.0,
                    18.0,
                    30.0,
                    16.0,
                    26.0,
                    32.0,
                    20.0,
                    14.0,
                  ];
                  return Container(
                    width: 6,
                    height: heights[index],
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              if (_audioPath != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildReviewInfoPill(
                      icon: Icons.graphic_eq_rounded,
                      label: 'Recorded voice',
                      foreground: Colors.white,
                      background: Colors.white.withValues(alpha: 0.14),
                    ),
                    _buildReviewInfoPill(
                      icon: Icons.access_time_rounded,
                      label: _formatDuration(_audioDuration),
                      foreground: Colors.white,
                      background: Colors.white.withValues(alpha: 0.12),
                    ),
                    _buildReviewInfoPill(
                      icon: Icons.description_outlined,
                      label: _storyController.text.trim().isNotEmpty
                          ? 'Transcript added'
                          : 'No transcript',
                      foreground: Colors.white,
                      background: Colors.white.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      case RecordStoryFormat.text:
        content = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.adaptiveBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.edit_note_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Written memory preview',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _storyController.text.trim().isEmpty
                      ? 'No written body yet.'
                      : _storyController.text.trim(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      case RecordStoryFormat.photoText:
        content = _photoFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.file(
                      _photoFile!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildPreviewBadge(
                        icon: Icons.photo_camera_back_outlined,
                        label: 'Attached photo',
                      ),
                    ),
                    if (_storyController.text.trim().isNotEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _storyController.text.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              height: 1.45,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : _buildEmptyMediaPreview(
                icon: Icons.collections_outlined,
                title: 'No photo attached yet',
                subtitle:
                    'Go back one step to choose the image you want attached to this memory.',
                accent: accent,
              );
      case RecordStoryFormat.video:
        content = Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE85D75), Color(0xFFB63D61), Color(0xFF1D2138)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -10,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: _buildPreviewBadge(
                  icon: Icons.videocam_outlined,
                  label: _videoFile != null ? 'Video attached' : 'Video format',
                ),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _videoFile != null
                          ? _fileName(_videoFile!.path)
                          : 'No video attached yet. Go back one step to choose a clip.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_storyController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _storyController.text.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached media',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.adaptiveTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  Widget _buildEmptyMediaPreview({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1D2138)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D2138),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewInfoPill({
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    final memory = _savedResult?['memory'] as Map<String, dynamic>?;
    final published = _savedResult?['status'] == 'published';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF5ABA82).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF5ABA82),
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            published
                ? 'Your memory is now part of the archive.'
                : 'Draft saved safely.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            published
                ? 'You can keep refining it later, but the memory is now visible in your recent memories.'
                : 'The draft is ready to resume whenever the next detail comes back to you.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
          if (memory != null) ...[
            const SizedBox(height: 20),
            _buildReviewCard(
              title: memory['title']?.toString() ?? 'Untitled memory',
              subtitle: memory['type']?.toString() ?? 'Memory',
              body: memory['description']?.toString().isNotEmpty == true
                  ? memory['description'].toString()
                  : 'No written description added.',
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(result: _savedResult),
                  child: const Text('Back Home'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: memory == null
                      ? null
                      : () => Get.to(() => MemoryDetailScreen(memory: memory)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5544FF),
                    minimumSize: const Size(0, 54),
                  ),
                  child: const Text('View Memory'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(RecordStoryFormat format) {
    final selected = format == _selectedFormat;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedFormat = format),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? format.accent.withValues(alpha: 0.12)
                : AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? format.accent.withValues(alpha: 0.44)
                  : AppTheme.adaptiveBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: format.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(format.icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      format.description,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.adaptiveTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? format.accent : AppTheme.adaptiveTextHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSummary(RecordStoryFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: format.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: format.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: format.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(format.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  format.label,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.adaptiveTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  format.description,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    height: 1.45,
                    color: AppTheme.adaptiveTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Voice capture'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.adaptiveCardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.adaptiveBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5544FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_none_rounded,
                      color: const Color(0xFF5544FF),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRecording ? 'Recording now' : 'Ready to record',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.adaptiveTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _audioPath != null
                              ? 'Clip captured: ${_formatDuration(_audioDuration)}'
                              : 'Tap once to start and again to stop.',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppTheme.adaptiveTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _toggleVoiceRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? const Color(0xFFE85D75)
                      : const Color(0xFF5544FF),
                  minimumSize: const Size(0, 52),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                ),
                label: Text(
                  _isRecording ? 'Stop recording' : 'Start recording',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Transcript or context'),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          focusNode: _storyFocusNode,
          onChanged: (_) => setState(() {}),
          maxLines: 7,
          onTapOutside: (_) => _dismissKeyboard(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _dismissKeyboard(),
          decoration: const InputDecoration(
            hintText:
                'Add the key details, names, or emotional context you want attached to this voice memory.',
          ),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Your memory'),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          focusNode: _storyFocusNode,
          onChanged: (_) => setState(() {}),
          maxLines: 11,
          onTapOutside: (_) => _dismissKeyboard(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _dismissKeyboard(),
          decoration: const InputDecoration(
            hintText:
                'Write the scene, the detail, the feeling, and why this moment matters.',
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Photo'),
        const SizedBox(height: 8),
        _buildMediaPickerCard(
          title: _photoFile == null
              ? 'Choose a photo'
              : _fileName(_photoFile!.path),
          subtitle: _photoFile == null
              ? 'Select from camera or gallery.'
              : 'Photo attached to this memory.',
          icon: Icons.collections_outlined,
          accent: const Color(0xFFE2923A),
          onTap: _pickPhoto,
          preview: _photoFile == null
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    _photoFile!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('What is happening here?'),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          focusNode: _storyFocusNode,
          onChanged: (_) => setState(() {}),
          maxLines: 8,
          onTapOutside: (_) => _dismissKeyboard(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _dismissKeyboard(),
          decoration: const InputDecoration(
            hintText:
                'Explain the image, the people in it, and the memory you want future-you to understand.',
          ),
        ),
      ],
    );
  }

  Widget _buildVideoComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Video'),
        const SizedBox(height: 8),
        _buildMediaPickerCard(
          title: _videoFile == null
              ? 'Choose a video'
              : _fileName(_videoFile!.path),
          subtitle: _videoFile == null
              ? 'Record a clip or choose one from your library.'
              : 'Video attached and ready for review.',
          icon: Icons.videocam_outlined,
          accent: const Color(0xFFE85D75),
          onTap: _pickVideo,
        ),
        const SizedBox(height: 18),
        _buildFieldLabel('Optional note'),
        const SizedBox(height: 8),
        TextField(
          controller: _storyController,
          focusNode: _storyFocusNode,
          onChanged: (_) => setState(() {}),
          maxLines: 6,
          onTapOutside: (_) => _dismissKeyboard(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _dismissKeyboard(),
          decoration: const InputDecoration(
            hintText:
                'Add names, context, or a reflection to accompany the clip.',
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPickerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    Widget? preview,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.adaptiveTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppTheme.adaptiveTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (preview != null) ...[const SizedBox(height: 16), preview],
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumPicker() {
    if (_isLoadingAlbums) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading albums...'),
          ],
        ),
      );
    }

    if (_albums.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Text(
          'No albums yet. You can publish this first and organize it into an album next.',
          style: GoogleFonts.outfit(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.adaptiveTextSecondary,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedAlbumId,
      decoration: const InputDecoration(hintText: 'Choose an album'),
      items: _albums.map((album) {
        final id = album['id']?.toString() ?? '';
        final title = album['title']?.toString() ?? 'Untitled album';
        return DropdownMenuItem<String>(value: id, child: Text(title));
      }).toList(),
      onChanged: (value) => setState(() => _selectedAlbumId = value),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(() => _selectedDate = date);
  }

  Widget _buildReviewCard({
    required String title,
    required String subtitle,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.adaptiveBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5544FF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.adaptiveTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.adaptiveTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.adaptiveTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.adaptiveTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_currentStep == 4) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
              ),
            ),
            const SizedBox(width: 12),
            if (_currentStep < 3)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _canAdvance ? _goNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5544FF),
                    minimumSize: const Size(0, 54),
                  ),
                  child: Text(_currentStep == 0 ? 'Choose format' : 'Continue'),
                ),
              )
            else
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _submitStory(publish: false),
                        child: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _submitStory(publish: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5544FF),
                          minimumSize: const Size(0, 54),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publish'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.adaptiveSoftSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.adaptiveBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.adaptiveTextPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adaptiveTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppTheme.adaptiveTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppTheme.adaptiveTextPrimary,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.adaptiveTextSecondary,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _fileName(String path) {
    return Uri.file(path).pathSegments.isEmpty
        ? path
        : Uri.file(path).pathSegments.last;
  }
}
