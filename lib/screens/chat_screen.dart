import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../backend/local_storage.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String uid;
  const ChatScreen({super.key, required this.uid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = AuthService();
  final _chat = ChatService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late final Stream<List<ChatMessage>> _messages = _chat.messagesStream;
  StreamSubscription<ChatUser?>? _profileSub;
  ChatUser? _me;

  @override
  void initState() {
    super.initState();
    // Right after sign-up the profile doc may not exist yet, so listen to it.
    _profileSub = _auth.profileStream(widget.uid).listen((user) {
      if (mounted) setState(() => _me = user);
    });
    NotificationService.instance.start(widget.uid);
  }

  Future<void> _send() async {
    final me = _me;
    final text = _msgCtrl.text.trim();
    if (me == null || text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await _chat.sendMessage(me, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.errorMessage(e))),
      );
    }
  }

  Future<void> _logout() async {
    // AuthGate shows the login screen once the user is signed out.
    await _auth.logout();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterChat'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                // Scroll to bottom on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final isMe = m.senderId == widget.uid;
                    return _MessageBubble(message: m, isMe: isMe);
                  },
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                decoration: const InputDecoration(
                  hintText: 'Send a message...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF4A148C)),
              onPressed: _me == null ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? const Color(0xFF4A148C) : Colors.grey.shade300;
    final textColor = isMe ? Colors.white : Colors.black87;

    final avatar = FutureBuilder<Uint8List?>(
      future: LocalStorage.instance.getData(message.senderImageUrl),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return CircleAvatar(
          radius: 18,
          backgroundColor: Colors.teal.shade300,
          backgroundImage: bytes != null ? MemoryImage(bytes) : null,
          child: bytes == null
              ? const Icon(Icons.person, size: 20, color: Colors.white)
              : null,
        );
      },
    );

    final bubble = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message.text, style: TextStyle(color: textColor)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '${message.senderName} · ${DateFormat.Hm().format(message.createdAt)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: isMe
                ? [bubble, const SizedBox(width: 8), avatar]
                : [avatar, const SizedBox(width: 8), bubble],
          ),
        ],
      ),
    );
  }
}
