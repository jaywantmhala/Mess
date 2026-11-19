// lib/models/vendor_notification.dart

class VendorNotification {
  final String id;
  final int rawId;
  final String source;
  final String title;
  final String body;
  final String type;
  final String? imageUrl;
  final String clickAction;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic> meta;

  VendorNotification({
    required this.id,
    required this.rawId,
    required this.source,
    required this.title,
    required this.body,
    required this.type,
    this.imageUrl,
    required this.clickAction,
    required this.createdAt,
    this.isRead = false,
    this.meta = const {},
  });

  factory VendorNotification.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return VendorNotification(
      id: json['id']?.toString() ?? '',
      rawId: json['raw_id'] is int
          ? json['raw_id']
          : int.tryParse(json['raw_id']?.toString() ?? '0') ?? 0,
      source: json['source']?.toString() ?? 'system',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      imageUrl: (json['image_url'] != null && json['image_url'].toString().trim().isNotEmpty)
          ? json['image_url'].toString().trim()
          : null,
      clickAction: json['click_action']?.toString() ?? 'HOME',
      createdAt: parsedDate,
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : {},
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
