import 'dart:typed_data';

import '../backend/local_auth.dart';
import '../backend/local_db.dart';
import '../backend/local_storage.dart';
import '../models/chat_user.dart';
import 'notification_service.dart';

class AuthService {
  final _auth = LocalAuth.instance;
  final _db = LocalDb.instance;
  final _storage = LocalStorage.instance;

  /// Emits the signed-in user, or null after logout.
  Stream<LocalUser?> get authStateChanges => _auth.authStateChanges();

  LocalUser? get currentUser => _auth.currentUser;

  /// Register: create the account, upload the photo to storage,
  /// and save the profile in the database (users/{uid}).
  Future<void> register({
    required String email,
    required String password,
    required String username,
    required Uint8List photo,
  }) async {
    final user = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      final imageUrl = await _storage.putData(
        'user_images/${user.uid}.jpg',
        photo,
      );
      final profile = ChatUser(
        uid: user.uid,
        email: user.email,
        username: username,
        imageUrl: imageUrl,
      );
      await _db.set('users', user.uid, profile.toMap(), merge: true);
    } catch (_) {
      // Don't leave a half-created account behind.
      await _auth.deleteCurrentUser();
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await NotificationService.instance.stop();
    await _auth.signOut();
  }

  /// Live profile from users/{uid}. Null until registration has saved it.
  Stream<ChatUser?> profileStream(String uid) =>
      _db.docSnapshots('users', uid).map((data) {
        if (data == null || data['username'] == null) return null;
        return ChatUser.fromMap(uid, data);
      });

  /// Turns auth error codes into readable messages.
  static String errorMessage(Object e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'The password must be at least 6 characters.';
      }
      return 'Authentication failed.';
    }
    return 'Something went wrong.';
  }
}
