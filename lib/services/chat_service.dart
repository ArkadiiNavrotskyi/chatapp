import '../backend/local_db.dart';
import '../backend/simulated_user.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';

class ChatService {
  final _db = LocalDb.instance;

  /// Live stream of all messages, oldest first.
  /// Emits again automatically when anyone sends a message.
  Stream<List<ChatMessage>> get messagesStream =>
      _db.collectionSnapshots('chat').map((docs) {
        final messages = docs.map(ChatMessage.fromMap).toList();
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      });

  Future<void> sendMessage(ChatUser me, String text) async {
    await _db.add('chat', {
      'senderId': me.uid,
      'senderName': me.username,
      'senderImageUrl': me.imageUrl,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    });
    SimulatedUser.replyLater();
  }
}
