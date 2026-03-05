import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

enum NotificationType { transaction, aiInsight, splitBill, budget, system }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimCtrl;

  final List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      title: 'Transaction Alert 💳',
      message: 'You spent ₹348 at Swiggy via UPI.',
      type: NotificationType.transaction,
      time: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: '2',
      title: 'AI Insight ✨',
      message:
          'Your food spending is 23% higher this week. Consider cooking at home to save ₹800.',
      type: NotificationType.aiInsight,
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: '3',
      title: 'SplitSync Request 🤝',
      message: 'Priya added you to "Goa Trip 2026". Your share: ₹4,200.',
      type: NotificationType.splitBill,
      time: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: '4',
      title: 'Budget Warning ⚠️',
      message: 'You have used 85% of your ₹5,000 Shopping budget for March.',
      type: NotificationType.budget,
      time: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: '5',
      title: 'Salary Credited 🎉',
      message: '₹65,000 has been credited to your account.',
      type: NotificationType.transaction,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '6',
      title: 'AI Insight ✨',
      message:
          'Great job! You saved ₹12,580 last month — 14% more than February.',
      type: NotificationType.aiInsight,
      time: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
    ),
    AppNotification(
      id: '7',
      title: 'SplitSync Settled 🎊',
      message: 'Aman settled ₹1,200 for "Dinner at Social".',
      type: NotificationType.splitBill,
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: '8',
      title: 'App Update 🚀',
      message:
          'SnapBudget v2.1 is here! New: Receipt scanning & voice logging.',
      type: NotificationType.system,
      time: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _dismiss(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  IconData _iconFor(NotificationType t) {
    switch (t) {
      case NotificationType.transaction:
        return Icons.receipt_long_rounded;
      case NotificationType.aiInsight:
        return Icons.auto_awesome_rounded;
      case NotificationType.splitBill:
        return Icons.call_split_rounded;
      case NotificationType.budget:
        return Icons.pie_chart_rounded;
      case NotificationType.system:
        return Icons.system_update_rounded;
    }
  }

  Color _colorFor(NotificationType t) {
    switch (t) {
      case NotificationType.transaction:
        return AppTheme.primaryPurple;
      case NotificationType.aiInsight:
        return const Color(0xFF7C3AED);
      case NotificationType.splitBill:
        return AppTheme.successGreen;
      case NotificationType.budget:
        return AppTheme.warningOrange;
      case NotificationType.system:
        return AppTheme.accentBlue;
    }
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
    // Group: today vs earlier
    final today = _notifications
        .where((n) => DateTime.now().difference(n.time).inHours < 24)
        .toList();
    final earlier = _notifications
        .where((n) => DateTime.now().difference(n.time).inHours >= 24)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_notifications.isEmpty) _buildEmptyState(),
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

  Widget _buildAppBar() {
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
        if (_unreadCount > 0)
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
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_unreadCount',
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

  Widget _buildNotificationTile(AppNotification notif) {
    final color = _colorFor(notif.type);
    final icon = _iconFor(notif.type);

    return Dismissible(
      key: Key(notif.id),
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
      onDismissed: (_) => _dismiss(notif.id),
      child: GestureDetector(
        onTap: () => setState(() => notif.isRead = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead
                ? AppTheme.cardWhite
                : AppTheme.primaryPurple.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: notif.isRead
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
                            notif.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notif.time),
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
                        color: notif.isRead
                            ? AppTheme.textMedium
                            : AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!notif.isRead)
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
