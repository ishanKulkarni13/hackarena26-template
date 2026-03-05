import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../models/alert_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimCtrl;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<NotificationProvider>().loadAlerts(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  void _markAllRead() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<NotificationProvider>().markAllAsRead(user.uid);
    }
  }

  void _dismiss(String id) {
    // Optional: add support for dismissing notifications in provider
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  IconData _iconFor(String type) {
    if (type.contains('budget')) return Icons.pie_chart_rounded;
    if (type.contains('spending')) return Icons.auto_awesome_rounded;
    if (type.contains('split')) return Icons.call_split_rounded;
    if (type.contains('payment')) return Icons.receipt_long_rounded;
    return Icons.notifications_rounded;
  }

  Color _colorFor(String type) {
    if (type.contains('budget')) return AppTheme.warningOrange;
    if (type.contains('spending')) return const Color(0xFF7C3AED);
    if (type.contains('split')) return AppTheme.successGreen;
    if (type.contains('payment')) return AppTheme.primaryPurple;
    return AppTheme.accentBlue;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.alerts;

    // Group: today vs earlier
    final today = notifications
        .where((n) => DateTime.now().difference(n.createdAt).inHours < 24)
        .toList();
    final earlier = notifications
        .where((n) => DateTime.now().difference(n.createdAt).inHours >= 24)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildAppBar(provider.unreadCount),
                if (notifications.isEmpty) _buildEmptyState(),
                if (today.isNotEmpty) ...[
                  _buildGroupHeader('Today'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildNotificationTile(today[i]),
                      childCount: today.length,
                    ),
                  ),
                ],
                if (earlier.isNotEmpty) ...[
                  _buildGroupHeader('Earlier'),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildNotificationTile(earlier[i]),
                      childCount: earlier.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildAppBar(int unreadCount) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            shape: BoxShape.circle,
            boxShadow: AppTheme.cardShadow,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppTheme.textDark,
          ),
        ),
      ),
      actions: [
        if (unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textLight,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 36,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No notifications right now.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AlertModel notif) {
    final color = _colorFor(notif.type);
    final icon = _iconFor(notif.type);
    final isRead = notif.status == AlertStatus.read;

    return Dismissible(
      key: Key(notif.alertId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.errorRed,
          size: 22,
        ),
      ),
      onDismissed: (_) => _dismiss(notif.alertId),
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            context.read<NotificationProvider>().markAsRead(notif.alertId);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? AppTheme.cardWhite
                : AppTheme.primaryPurple.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isRead
                  ? Colors.transparent
                  : AppTheme.primaryPurple.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.type.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notif.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isRead ? AppTheme.textMedium : AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
