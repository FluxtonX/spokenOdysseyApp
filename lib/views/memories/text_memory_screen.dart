import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/memory_service.dart';
import '../../theme/theme.dart';

class TextMemoryScreen extends StatefulWidget {
  const TextMemoryScreen({super.key, this.albumId});

  final String? albumId;

  @override
  State<TextMemoryScreen> createState() => _TextMemoryScreenState();
}

class _TextMemoryScreenState extends State<TextMemoryScreen> {
  final MemoryService _memoryService = MemoryService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  Color _selectedBgColor = Colors.white;
  bool _isSaving = false;

  final List<Color> _bgColors = [
    Colors.white,
    const Color(0xFFFDE8E8), // Light Red
    const Color(0xFFE1EFFE), // Light Blue
    const Color(0xFFEBF5FF), // Light Indigo
    const Color(0xFFF3FAF7), // Light Green
    const Color(0xFFFEF9C3), // Light Yellow
    const Color(0xFFFDF2F8), // Light Pink
    const Color(0xFFF5F3FF), // Light Purple
  ];

  Future<void> _saveMemory() async {
    final title = _titleController.text.trim();
    final text = _textController.text.trim();
    
    if (title.isEmpty || text.isEmpty) {
      Get.snackbar('Error', 'Please enter both title and text');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // For Text memories, we can pass the background color info in the description or as a tag if needed,
      // but for now let's just save the text as requested.
      final memory = await _memoryService.createMemory(
        title: title,
        description: text,
        tags: const [],
        mood: 'Reflective',
        privacy: 'Private',
        type: 'Text',
        publish: true,
        occurredAt: DateTime.now(),
        albumId: widget.albumId,
        color: '#${_selectedBgColor.value.toRadixString(16).padLeft(8, '0')}',
        mediaFile: null,
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
        title: Text('New Text Memory', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frame Color', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _bgColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final color = _bgColors[index];
                  final isSelected = _selectedBgColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBgColor = color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF5D5FEF) : Colors.black12,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF5D5FEF).withValues(alpha: 0.2), blurRadius: 8)] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 20, color: Color(0xFF5D5FEF)) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text('Title', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Enter title for this memory'),
            ),
            const SizedBox(height: 24),
            Text('Memory Text', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: TextField(
                controller: _textController,
                maxLines: 12,
                style: GoogleFonts.outfit(fontSize: 16, height: 1.5, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Start writing your memory here...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Add Memory', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
