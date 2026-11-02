import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Local stand-in for Firebase Storage. Uploaded bytes are kept in local
/// storage (works on Android, iOS and web) and addressed by a URL like
/// `local-storage://user_images/uid.jpg`.
class LocalStorage {
  LocalStorage._();
  static final instance = LocalStorage._();

  static const scheme = 'local-storage://';

  final _cache = <String, Future<Uint8List?>>{};

  /// Uploads [bytes] to [path] (e.g. 'user_images/uid.jpg') and returns its URL.
  Future<String> putData(String path, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_$path', base64Encode(bytes));
    final url = '$scheme$path';
    _cache[url] = Future.value(bytes);
    return url;
  }

  /// Downloads the bytes behind a URL returned by [putData].
  Future<Uint8List?> getData(String url) => _cache.putIfAbsent(url, () async {
    if (!url.startsWith(scheme)) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('storage_${url.substring(scheme.length)}');
    return raw == null ? null : base64Decode(raw);
  });
}
