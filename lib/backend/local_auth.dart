import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local stand-in for FirebaseAuth. Same shape: a signed-in user stream,
/// email/password sign-up and sign-in, sign-out, and the same error codes.
/// Passwords are stored as salted SHA-256 hashes, never in plain text.
class LocalUser {
  final String uid;
  final String email;
  const LocalUser({required this.uid, required this.email});
}

class AuthException implements Exception {
  final String code;
  const AuthException(this.code);

  @override
  String toString() => 'AuthException($code)';
}

class LocalAuth {
  LocalAuth._();
  static final instance = LocalAuth._();

  static const _accountsKey = 'auth_accounts';
  static const _sessionKey = 'auth_session_uid';

  final _changes = StreamController<LocalUser?>.broadcast();
  LocalUser? _current;
  bool _restored = false;

  LocalUser? get currentUser => _current;

  /// Emits the current user on listen, then on every sign-in / sign-out.
  Stream<LocalUser?> authStateChanges() async* {
    await _restoreSession();
    yield _current;
    yield* _changes.stream;
  }

  Future<LocalUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (!key.contains('@') || !key.contains('.')) {
      throw const AuthException('invalid-email');
    }
    if (password.length < 6) throw const AuthException('weak-password');

    final accounts = await _loadAccounts();
    if (accounts.containsKey(key)) {
      throw const AuthException('email-already-in-use');
    }

    final salt = _randomSalt();
    final uid = const Uuid().v4();
    accounts[key] = {
      'uid': uid,
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await _saveAccounts(accounts);

    final user = LocalUser(uid: uid, email: key);
    await _setCurrent(user);
    return user;
  }

  Future<LocalUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (!key.contains('@')) throw const AuthException('invalid-email');

    final account = (await _loadAccounts())[key];
    if (account == null ||
        account['hash'] != _hash(password, account['salt'] as String)) {
      // Like Firebase: don't reveal whether the email exists.
      throw const AuthException('invalid-credential');
    }

    final user = LocalUser(uid: account['uid'] as String, email: key);
    await _setCurrent(user);
    return user;
  }

  Future<void> signOut() => _setCurrent(null);

  /// Removes the signed-in account (used to roll back a failed sign-up).
  Future<void> deleteCurrentUser() async {
    final user = _current;
    if (user == null) return;
    final accounts = await _loadAccounts();
    accounts.remove(user.email);
    await _saveAccounts(accounts);
    await _setCurrent(null);
  }

  Future<void> _restoreSession() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionKey);
    if (uid == null) return;
    final accounts = await _loadAccounts();
    for (final entry in accounts.entries) {
      if (entry.value['uid'] == uid) {
        _current = LocalUser(uid: uid, email: entry.key);
      }
    }
  }

  Future<void> _setCurrent(LocalUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, user.uid);
    }
    _current = user;
    _changes.add(user);
  }

  Future<Map<String, Map<String, dynamic>>> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
  }

  Future<void> _saveAccounts(Map<String, Map<String, dynamic>> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  static String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _randomSalt() {
    final rnd = Random.secure();
    return base64Url.encode(List.generate(16, (_) => rnd.nextInt(256)));
  }
}
