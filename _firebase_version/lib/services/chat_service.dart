import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/chat_user.dart';

class ChatService {
  final _messages = FirebaseFirestore.instance.collection('chat');

  /// Live stream of all messages, oldest first.
  /// Firestore pushes updates automatically when someone sends a message.
  Stream<List<ChatMessage>> get messagesStream => _messages
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());

  Future<void> sendMessage(ChatUser me, String text) async {
    await _messages.add({
      'senderId': me.uid,
      'senderName': me.username,
      'senderImageUrl': me.imageUrl,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
