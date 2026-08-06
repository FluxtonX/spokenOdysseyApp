import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../memories/presentation/cubits/memories_cubit.dart';
import '../../../memories/presentation/widgets/create_memory_modal.dart';
import '../cubit/record_cubit.dart';
import '../widgets/waveform_visualizer.dart';

class RecordStudioPage extends StatelessWidget {
  const RecordStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecordCubit>(
      create: (context) => sl<RecordCubit>(),
      child: const _RecordStudioView(),
    );
  }
}

class _RecordStudioView extends StatelessWidget {
  const _RecordStudioView();

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: BlocConsumer<RecordCubit, RecordState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            final isRecording = state.status == RecordStatus.recording;
            final isPaused = state.status == RecordStatus.paused;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title Header
                  Column(
                    children: [
                      Text(
                        'Voice Odyssey Studio',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record your thoughts, family history, or wisdom.',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Waveform & Timer Container
                  Column(
                    children: [
                      Text(
                        _formatDuration(state.duration),
                        style: GoogleFonts.outfit(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: isRecording ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 80,
                        child: WaveformVisualizer(isRecording: isRecording),
                      ),
                    ],
                  ),

                  // Mic Controls
                  Column(
                    children: [
                      if (state.status == RecordStatus.idle) ...[
                        GestureDetector(
                          onTap: () {
                            context.read<RecordCubit>().startRecording();
                          },
                          child: Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to Start Recording',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Pause / Resume
                            IconButton(
                              iconSize: 48,
                              icon: Icon(
                                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                if (isPaused) {
                                  context.read<RecordCubit>().resumeRecording();
                                } else {
                                  context.read<RecordCubit>().pauseRecording();
                                }
                              },
                            ),
                            const SizedBox(width: 24),

                            // Mic Pulse Button (Active)
                            Container(
                              height: 90,
                              width: 90,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.graphic_eq_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Stop & Finish
                            IconButton(
                              iconSize: 48,
                              icon: const Icon(
                                Icons.stop_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                final path = await context.read<RecordCubit>().stopRecording();
                                if (path != null && context.mounted) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    builder: (_) => BlocProvider.value(
                                      value: sl<MemoriesCubit>(),
                                      child: CreateMemoryModal(initialAudioPath: path),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.read<RecordCubit>().reset();
                              },
                              child: Text(
                                'Reset Recording',
                                style: GoogleFonts.outfit(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
