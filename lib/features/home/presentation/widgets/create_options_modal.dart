import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../albums/presentation/cubits/albums_cubit.dart';
import '../../../albums/presentation/widgets/create_album_modal.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/widgets/create_memory_modal.dart';

class CreateOptionsModal extends StatelessWidget {
  final VoidCallback onRecordVoiceStory;

  const CreateOptionsModal({
    super.key,
    required this.onRecordVoiceStory,
  });

  static void show(BuildContext parentContext, {required VoidCallback onRecordVoiceStory}) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CreateOptionsModal(onRecordVoiceStory: onRecordVoiceStory);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create & Record',
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
          const SizedBox(height: 16),

          // Option 1: Record Voice Story
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mic_rounded, color: AppColors.primary),
            ),
            title: Text(
              'Record Voice Story',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              'Record audio story directly with live waveform visualizer',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
            ),
            onTap: () {
              Navigator.pop(context);
              onRecordVoiceStory();
            },
          ),
          const Divider(height: 16),

          // Option 2: Create Memory Story
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.post_add_rounded, color: AppColors.primary),
            ),
            title: Text(
              'Create Memory',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              'Add title, story description, media, tags & privacy',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
            ),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => BlocProvider.value(
                  value: context.read<MemoriesCubit>(),
                  child: const CreateMemoryModal(),
                ),
              );
            },
          ),
          const Divider(height: 16),

          // Option 3: Create Album
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.folder_special_rounded, color: AppColors.primary),
            ),
            title: Text(
              'Create Memory Album',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              'Organize memories into custom themed albums',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
            ),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => BlocProvider.value(
                  value: context.read<AlbumsCubit>(),
                  child: const CreateAlbumModal(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
