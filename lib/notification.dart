import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({super.key});

  // Dummy data untuk tampilan UI saja
  final List<NotificationItem> today = [
    NotificationItem(
      title: 'Appointment Success',
      message:
          'You have successfully booked your appointment with Dr. Emily Walker.',
      timeLabel: '1h',
      type: NotificationType.success,
      isHighlighted: true,
    ),
    NotificationItem(
      title: 'Appointment Cancelled',
      message:
          'You have successfully cancelled your appointment with Dr. David Patel.',
      timeLabel: '2h',
      type: NotificationType.cancelled,
      isHighlighted: true,
    ),
    NotificationItem(
      title: 'Scheduled Changed',
      message:
          'You have successfully changes your appointment with Dr. Jesica Turner.',
      timeLabel: '8h',
      type: NotificationType.changed,
      isHighlighted: true,
    ),
  ];

  final List<NotificationItem> yesterday = [
    NotificationItem(
      title: 'Appointment success',
      message:
          'You have successfully booked your appointment with Dr. David Patel.',
      timeLabel: '1d',
      type: NotificationType.success,
      isHighlighted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final allNotifications = [...today, ...yesterday];
    final unreadCount = allNotifications.length; // sementara semua dianggap new

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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
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
          const _SectionHeader(title: 'TODAY'),
          ...today.map((n) => NotificationTile(item: n)).toList(),
          const SizedBox(height: 8),
          const _SectionHeader(title: 'YESTERDAY'),
          ...yesterday.map((n) => NotificationTile(item: n)).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

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
          const Text(
            'Mark all as read',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E5EFF),
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

    return Container(
      color: item.isHighlighted ? Colors.white : const Color(0xFFF5F6FA),
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
              child: Icon(
                Icons.calendar_today,
                color: mainColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.timeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF35A772); // hijau lembut
      case NotificationType.cancelled:
        return const Color(0xFFE35B5B); // merah lembut
      case NotificationType.changed:
        return const Color(0xFF8A9BB6); // abu kebiruan
    }
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String timeLabel; // contoh: "1h", "2h", "8h", "1d"
  final NotificationType type;
  final bool isHighlighted;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.type,
    this.isHighlighted = true,
  });
}

enum NotificationType {
  success,
  cancelled,
  changed,
}