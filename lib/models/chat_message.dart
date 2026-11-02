class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImageUrl;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImageUrl,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) => ChatMessage(
    id: data['id'] as String? ?? '',
    senderId: data['senderId'] as String? ?? '',
    senderName: data['senderName'] as String? ?? '',
    senderImageUrl: data['senderImageUrl'] as String? ?? '',
    text: data['text'] as String? ?? '',
    createdAt:
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}
