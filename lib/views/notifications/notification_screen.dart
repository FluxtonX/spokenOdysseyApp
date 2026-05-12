import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../theme/theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adaptiveScaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.adaptiveScaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.adaptiveTextPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: AppTheme.adaptiveTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('New'),
          _buildNotificationCard(
            title: 'Family Invitation',
            message: 'Sarah invited you to join the "Smith Family" archive.',
            time: '2 mins ago',
            icon: Icons.group_add_rounded,
            color: const Color(0xFF8B7BFF),
            isUnread: true,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'Album Updated',
            message: 'New memories were added to "Summer 2024".',
            time: '1 hour ago',
            icon: Icons.auto_awesome_mosaic_rounded,
            color: const Color(0xFF4CB88C),
            isUnread: true,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Earlier'),
          _buildNotificationCard(
            title: 'Memory Remembered',
            message: 'You have a new memory from 2 years ago today.',
            time: 'Yesterday',
            icon: Icons.history_rounded,
            color: const Color(0xFFF08855),
            isUnread: false,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'Welcome Back',
            message: 'Start your week by recording a quick story.',
            time: '2 days ago',
            icon: Icons.celebration_rounded,
            color: const Color(0xFFFFB347),
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.adaptiveTextSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color color,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.adaptiveCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread 
              ? color.withValues(alpha: 0.3) 
              : AppTheme.adaptiveTextPrimary.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adaptiveTextPrimary,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.adaptiveTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.adaptiveTextSecondary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
