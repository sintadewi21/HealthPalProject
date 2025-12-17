import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _marking = false;
  final supabase = Supabase.instance.client;
  List<NotificationItem> items = [];
  StreamSubscription? _sub;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _listenRealtime();
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

  Future<void> _markIdsAsRead(List<String> ids) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    if (ids.isEmpty) return;
    if (_marking) return;

    setState(() => _marking = true);

    try {
      // Minta return id yang ter-update biar kita bisa update UI lokal juga
      final updated = await supabase
          .from('notifications')
          .update({'status': 'read'})
          .eq('user_id', user.id)
          .inFilter('notification_id', ids)
          .select('notification_id');

      final updatedIds = (updated as List)
          .map((e) => (e as Map<String, dynamic>)['notification_id'] as String)
          .toSet();

      // Update UI lokal langsung (biar tile jadi abu + badge turun)
      setState(() {
        items = items
            .map((n) => updatedIds.contains(n.id) ? n.copyWith(status: 'read') : n)
            .toList();
      });

      // Optional: reload sebagai safety
      // await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mark all failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final unreadCount = items.where((x) => x.status == 'unread').length;

    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    bool isYesterday(DateTime d) {
      final y = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      return d.year == y.year && d.month == y.month && d.day == y.day;
    }

    final today = items.where((x) => isToday(x.createdAt)).toList();
    final yesterday = items.where((x) => isYesterday(x.createdAt)).toList();

    final todayUnreadIds =
        today.where((x) => x.status == 'unread').map((x) => x.id).toList();
    final yesterdayUnreadIds =
        yesterday.where((x) => x.status == 'unread').map((x) => x.id).toList();

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
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount New',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _SectionHeader(
            title: 'TODAY',
            enabled: !_marking && todayUnreadIds.isNotEmpty,
            onMarkAll: () => _markIdsAsRead(todayUnreadIds),
          ),
          ...today.map((n) => NotificationTile(item: n)).toList(),

          _SectionHeader(
            title: 'YESTERDAY',
            enabled: !_marking && yesterdayUnreadIds.isNotEmpty,
            onMarkAll: () => _markIdsAsRead(yesterdayUnreadIds),
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
  final bool enabled;

  const _SectionHeader({
    required this.title,
    required this.onMarkAll,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(top: 14, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9AA3AE),
              letterSpacing: 0.4,
            ),
          ),
          InkWell(
            onTap: enabled ? onMarkAll : null,
            child: Text(
              'Mark all as read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black : const Color(0xFFB8C0CC),
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
      color: isHighlighted ? Colors.white : const Color(0xFFF0F2F6),
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

  // ✅ Tambahan: biar bisa update status di UI setelah mark-all
  NotificationItem copyWith({
    String? message,
    NotificationType? type,
    String? status,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

    final createdRaw = map['created_at'];
    final createdAt = createdRaw is String
        ? DateTime.parse(createdRaw).toLocal()
        : (createdRaw as DateTime).toLocal();

    return NotificationItem(
      id: map['notification_id'] as String,
      message: (map['message'] as String?) ?? '',
      type: type,
      status: (map['status'] as String?) ?? 'unread',
      createdAt: createdAt,
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