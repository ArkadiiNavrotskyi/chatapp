import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/chat_message.dart';
import 'chat_service.dart';

/// Shows a notification when a message from another user arrives while the
/// app is in the background (stands in for Firebase Cloud Messaging).
class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StreamSubscription<List<ChatMessage>>? _sub;
  AppLifecycleState _state = AppLifecycleState.resumed;

  /// Call once in main().
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  /// Start listening for incoming messages for the signed-in user.
  Future<void> start(String uid) async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _sub?.cancel();
    Set<String>? seen;
    _sub = ChatService().messagesStream.listen((messages) {
      final ids = messages.map((m) => m.id).toSet();
      if (seen != null && _state != AppLifecycleState.resumed) {
        for (final m in messages) {
          if (!seen!.contains(m.id) && m.senderId != uid) _show(m);
        }
      }
      seen = ids;
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _state = state;

  Future<void> _show(ChatMessage m) => _plugin.show(
    id: m.id.hashCode,
    title: m.senderName,
    body: m.text,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_channel',
        'Chat messages',
        channelDescription: 'Incoming chat messages',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}
