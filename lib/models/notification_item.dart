/// Model for a saved notification
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? chatId;
  final String? senderId;
  final String? type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.chatId,
    this.senderId,
    this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'chatId': chatId,
        'senderId': senderId,
        'type': type,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
      chatId: json['chatId']?.toString(),
      senderId: json['senderId']?.toString(),
      type: json['type']?.toString(),
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? chatId,
    String? senderId,
    String? type,
  }) =>
      NotificationItem(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        type: type ?? this.type,
      );
}
