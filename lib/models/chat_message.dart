class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String status;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.status = 'sent',
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      status: json['status'] ?? 'sent',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
