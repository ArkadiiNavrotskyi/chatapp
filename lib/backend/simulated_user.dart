import 'dart:async';
import 'dart:math';

import 'local_db.dart';

/// A simulated second user, so incoming messages and notifications can be
/// shown on a single device. Replies a few seconds after you send a message:
/// send one, then press Home to see the notification.
class SimulatedUser {
  SimulatedUser._();

  static const uid = 'simulated-maximilian';
  static const name = 'Maximilian';

  static const _replies = [
    'Hi anybody here?',
    'Awesome!',
    'Hey, how are you?',
    'Nice to meet you 👋',
    'That sounds cool.',
    'Haha, yes!',
  ];

  static final _rnd = Random();

  static void replyLater() {
    Timer(const Duration(seconds: 4), () {
      LocalDb.instance.add('chat', {
        'senderId': uid,
        'senderName': name,
        'senderImageUrl': '',
        'text': _replies[_rnd.nextInt(_replies.length)],
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
  }
}
