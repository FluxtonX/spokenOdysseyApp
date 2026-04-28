import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../services/memory_service.dart';
import '../../theme/theme.dart';

class VoiceMemoryScreen extends StatefulWidget {
  const VoiceMemoryScreen({super.key, this.albumId});

  final String? albumId;

  @override
  State<VoiceMemoryScreen> createState() => _VoiceMemoryScreenState();
}

class _VoiceMemoryScreenState extends State<VoiceMemoryScreen> with TickerProviderStateMixin {
  final MemoryService _memoryService = MemoryService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isRecording = false;
  String? _audioPath;
  Duration _duration = Duration.zero;
  Timer? _timer;
  bool _isSaving = false;
  
  late AnimationController _waveController;
  final List<double> _waveValues = List.generate(20, (_) => 0.2);

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
        if (_isRecording) {
          setState(() {
            for (int i = 0; i < _waveValues.length; i++) {
              _waveValues[i] = 0.2 + math.Random().nextDouble() * 0.8;
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(const RecordConfig(), path: path);

    setState(() {
      _isRecording = true;
      _audioPath = null;
      _duration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _duration += const Duration(seconds: 1));
    });
    
    _waveController.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    _waveController.stop();

    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  Future<void> _saveMemory() async {
    if (_audioPath == null) return;
    
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Error', 'Please enter a title');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final memory = await _memoryService.createMemory(
        title: title,
        description: _descriptionController.text.trim(),
        tags: const [],
        mood: 'Reflective',
        privacy: 'Private',
        type: 'Voice',
        publish: true,
        occurredAt: DateTime.now(),
        albumId: widget.albumId,
        mediaFile: File(_audioPath!),
      );

      Get.back(result: {'status': 'published', 'memory': memory});
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text('New Voice Memory', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                _formatDuration(_duration),
                style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w700, color: const Color(0xFF5D5FEF)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _waveValues.map((val) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 6,
                    height: _isRecording ? (val * 80) : 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D5FEF).withValues(alpha: _isRecording ? 1.0 : 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.redAccent : const Color(0xFF5D5FEF),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.redAccent : const Color(0xFF5D5FEF)).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'Tap to stop' : 'Tap to start recording',
              style: GoogleFonts.outfit(color: AppTheme.adaptiveTextSecondary),
            ),
            if (_audioPath != null && !_isRecording) ...[
              const SizedBox(height: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Title', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Give this recording a name'),
                  ),
                  const SizedBox(height: 20),
                  Text('Description', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'What is this recording about?'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMemory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D5FEF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Add Memory', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
