import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;

  List<NotificationItem> items = [];
  StreamSubscription? _sub;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _listenRealtime();
    _markAllAsRead();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      items = (res as List)
          .map((e) => NotificationItem.fromMap(e as Map<String, dynamic>))
          .toList();
      loading = false;
    });
  }

  void _listenRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _sub = supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .listen((data) {
      setState(() {
        items = data.map((e) => NotificationItem.fromMap(e)).toList();
        loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('notifications')
        .update({'status': 'read'})
        .eq('user_id', user.id)
        .eq('status', 'unread');

    // realtime stream akan auto update UI, tapi aman juga panggil _load() kalau perlu
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = items.where((x) => x.status == 'unread').length;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    bool isYesterday(DateTime d) {
      final y = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      return d.year == y.year && d.month == y.month && d.day == y.day;
    }

    final today = items.where((x) => isToday(x.createdAt)).toList();
    final yesterday = items.where((x) => isYesterday(x.createdAt)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E5EFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$unreadCount New',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(
            title: 'TODAY',
            onMarkAll: _markAllAsRead,
          ),
          ...today.map((n) => NotificationTile(item: n)).toList(),
          const SizedBox(height: 8),
          _SectionHeader(
            title: 'YESTERDAY',
            onMarkAll: _markAllAsRead,
          ),
          ...yesterday.map((n) => NotificationTile(item: n)).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMarkAll;

  const _SectionHeader({required this.title, required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0)
          .copyWith(top: 12, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: onMarkAll,
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E5EFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationItem item;

  const NotificationTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final Color mainColor = _colorForType(item.type);
    final bool isHighlighted = item.status == 'unread';

    return Container(
      color: isHighlighted ? Colors.white : const Color(0xFFF5F6FA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE4E6EB), width: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: mainColor.withOpacity(0.15),
              child: Icon(Icons.calendar_today, color: mainColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_timeAgoLabel(item.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  static String _timeAgoLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF35A772);
      case NotificationType.cancelled:
        return const Color(0xFFE35B5B);
      case NotificationType.changed:
        return const Color(0xFF8A9BB6);
    }
  }
}

enum NotificationType { success, cancelled, changed }

class NotificationItem {
  final String id;
  final String message;
  final NotificationType type;
  final String status; // 'unread' / 'read'
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    final t = (map['notif_type'] as String?) ?? 'changed';

    final NotificationType type;
    switch (t) {
      case 'success':
        type = NotificationType.success;
        break;
      case 'cancelled':
        type = NotificationType.cancelled;
        break;
      default:
        type = NotificationType.changed;
    }

    return NotificationItem(
      id: map['notification_id'] as String,
      message: map['message'] as String,
      type: type,
      status: (map['status'] as String?) ?? 'unread',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  String get title {
    switch (type) {
      case NotificationType.success:
        return 'Appointment Success';
      case NotificationType.cancelled:
        return 'Appointment Cancelled';
      case NotificationType.changed:
        return 'Scheduled Changed';
    }
  }
}