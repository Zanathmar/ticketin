import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../shared/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_NotifItem> _notifications = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _buildNotifications();
  }

  void _buildNotifications() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final now = DateTime.now();
    final items = <_NotifItem>[];

    if (user.isAttendee) {
      items.addAll([
        _NotifItem(
          icon: Icons.confirmation_number_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primary.withOpacity(0.15),
          title: 'Welcome to Ticketin',
          body: 'Browse upcoming events and register with one tap. Your QR ticket will appear in My Tickets.',
          time: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        _NotifItem(
          icon: Icons.qr_code_2,
          iconColor: AppColors.activeGreen,
          iconBg: AppColors.activeBg,
          title: 'How check-in works',
          body: 'At the event entrance, show your QR code from My Tickets to the organizer for scanning.',
          time: now.subtract(const Duration(hours: 1)),
          isRead: false,
        ),
        _NotifItem(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.completedBlue,
          iconBg: AppColors.completedBg,
          title: 'First come, first served',
          body: 'Tickets are limited. Register early to secure your spot — capacity fills up fast.',
          time: now.subtract(const Duration(hours: 3)),
          isRead: true,
        ),
      ]);
    }

    if (user.isOrganizer || user.isAdmin) {
      items.addAll([
        _NotifItem(
          icon: Icons.add_circle_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primary.withOpacity(0.15),
          title: 'Create your first event',
          body: 'Tap the + New Event button on the Home screen to publish an event with venue, capacity, and image.',
          time: now.subtract(const Duration(minutes: 2)),
          isRead: false,
        ),
        _NotifItem(
          icon: Icons.qr_code_scanner,
          iconColor: AppColors.activeGreen,
          iconBg: AppColors.activeBg,
          title: 'Scanner ready',
          body: 'Use the QR scan button in the center of the bottom bar to check attendees in and out during your event.',
          time: now.subtract(const Duration(minutes: 30)),
          isRead: false,
        ),
        _NotifItem(
          icon: Icons.people_alt_rounded,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningLight,
          title: 'Track attendance',
          body: 'View real-time attendance and check-in status for all your events from the admin panel.',
          time: now.subtract(const Duration(hours: 2)),
          isRead: true,
        ),
        _NotifItem(
          icon: Icons.security_rounded,
          iconColor: AppColors.completedBlue,
          iconBg: AppColors.completedBg,
          title: 'HMAC-secured QR codes',
          body: 'Each ticket uses a cryptographic nonce so QR codes cannot be forged or duplicated.',
          time: now.subtract(const Duration(days: 1)),
          isRead: true,
        ),
      ]);
    }

    setState(() {
      _notifications
        ..clear()
        ..addAll(items);
      _loaded = true;
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markRead(int index) {
    setState(() => _notifications[index].isRead = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final n = _notifications[i];
        return _NotifCard(
          item: n,
          onTap: () => _markRead(i),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text('No notifications', style: AppTextStyles.headline3),
          const SizedBox(height: 8),
          Text(
            'You are all caught up.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final DateTime time;
  bool isRead;

  _NotifItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifItem item;
  final VoidCallback onTap;
  const _NotifCard({required this.item, required this.onTap});

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.card : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? AppColors.cardBorder : AppColors.primary.withOpacity(0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: item.isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(item.time),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted, fontSize: 11),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
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
}