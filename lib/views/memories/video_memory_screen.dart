import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../services/memory_service.dart';
import '../../theme/theme.dart';
import '../../utils/image_picker_helper.dart';

class VideoMemoryScreen extends StatefulWidget {
  const VideoMemoryScreen({super.key, this.albumId});

  final String? albumId;

  @override
  State<VideoMemoryScreen> createState() => _VideoMemoryScreenState();
}

class _VideoMemoryScreenState extends State<VideoMemoryScreen> {
  final MemoryService _memoryService = MemoryService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _videoFile;
  VideoPlayerController? _videoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickVideo());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await ImagePickerHelper.pickVideoWithSourceSheet(context);
    if (file == null) {
      if (mounted && _videoFile == null) Get.back();
      return;
    }

    _videoController?.dispose();
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      setState(() {
        _videoFile = file;
        _videoController = controller;
      });
    } catch (e) {
      Get.snackbar('Error', 'Could not preview video');
      setState(() {
        _videoFile = file;
        _videoController = null;
      });
    }
  }

  Future<void> _saveMemory() async {
    if (_videoFile == null) return;

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
        type: 'Video',
        publish: true,
        occurredAt: DateTime.now(),
        albumId: widget.albumId,
        mediaFile: _videoFile,
      );

      Get.back(result: {'status': 'published', 'memory': memory});
    } catch (e) {
      setState(() => _isSaving = false);
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text('New Video Memory',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: _videoFile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickVideo,
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_videoController != null &&
                              _videoController!.value.isInitialized)
                            Center(
                              child: AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          else
                            const Center(
                              child: Icon(Icons.videocam_outlined,
                                  size: 48, color: Colors.white24),
                            ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_outline_rounded,
                                size: 64, color: Colors.white70),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Change Video',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Title',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: 'Enter title',
                      filled: true,
                      fillColor: AppTheme.adaptiveCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Description',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      hintText: 'What happened in this video?',
                      filled: true,
                      fillColor: AppTheme.adaptiveCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMemory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D5FEF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Add Memory',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

