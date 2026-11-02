import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // createdAt is null for a moment while the server timestamp is pending.
    final ts = data['createdAt'] as Timestamp?;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderImageUrl: data['senderImageUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}
