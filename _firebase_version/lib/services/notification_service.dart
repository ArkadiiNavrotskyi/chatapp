import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Registers this device for push notifications (FCM).
///
/// The device's FCM id (Firebase Installation ID) is stored in
/// users/{uid}.fcmId. The Cloud Function in functions/index.js sends a
/// notification to every other user's id when a new message is written to the
/// `chat` collection. Android shows it automatically when the app is in the
/// background or closed.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<String>? _registeredSub;

  Future<void> init(String uid) async {
    await _fcm.requestPermission();

    await _registeredSub?.cancel();
    _registeredSub = _fcm.onRegistered.listen(
      (fid) => _db
          .collection('users')
          .doc(uid)
          .set({'fcmId': fid}, SetOptions(merge: true)),
    );
    await _fcm.register();
  }

  Future<void> removeToken(String uid) async {
    await _registeredSub?.cancel();
    _registeredSub = null;
    await _db
        .collection('users')
        .doc(uid)
        .set({'fcmId': FieldValue.delete()}, SetOptions(merge: true));
    await _fcm.unregister();
  }
}
