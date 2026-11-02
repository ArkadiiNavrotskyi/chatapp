import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/chat_user.dart';
import 'notification_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Emits the signed-in user, or null after logout.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Register: create the Auth account, upload the photo to Storage,
  /// and save the profile in Firestore (users/{uid}).
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required File photo,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    try {
      final ref = _storage.ref().child('user_images').child('$uid.jpg');
      await ref.putFile(photo);
      final imageUrl = await ref.getDownloadURL();

      final user = ChatUser(
        uid: uid,
        email: email,
        username: username,
        imageUrl: imageUrl,
      );
      // merge: the FCM token may already have been written to this doc.
      await _db
          .collection('users')
          .doc(uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (_) {
      // Don't leave a half-created account behind.
      await cred.user!.delete();
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) await NotificationService.instance.removeToken(uid);
    await _auth.signOut();
  }

  /// Live profile from users/{uid}. Null until registration has saved it.
  Stream<ChatUser?> profileStream(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((doc) {
        final data = doc.data();
        if (data == null || data['username'] == null) return null;
        return ChatUser.fromMap(uid, data);
      });

  /// Turns Firebase error codes into readable messages.
  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
      }
      return e.message ?? 'Authentication failed.';
    }
    if (e is FirebaseException) return e.message ?? 'Something went wrong.';
    return 'Something went wrong.';
  }
}
