import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Payment Received',
      'message': 'Priya paid ₹3,125 for Goa Trip',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'icon': Icons.check_circle_rounded,
      'iconColor': AppTheme.successGreen,
    },
    {
      'id': '2',
      'title': 'Payment Reminder',
      'message': 'Karan & Riya haven\'t paid for Goa Trip yet',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'icon': Icons.info_rounded,
      'iconColor': AppTheme.warningOrange,
    },
    {
      'id': '3',
      'title': 'Bill Settled',
      'message': 'Dinner at Punjab Grill has been settled',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.done_all_rounded,
      'iconColor': AppTheme.successGreen,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textDark,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _notificationItem(notification);
        },
      ),
    );
  }

  Widget _notificationItem(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (notification['iconColor'] as Color).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                notification['icon'] as IconData,
                color: notification['iconColor'] as Color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimeAgo(notification['timestamp'] as DateTime),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

