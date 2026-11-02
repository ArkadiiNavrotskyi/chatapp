import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local stand-in for Cloud Firestore: named collections of JSON documents
/// with live streams that emit again whenever a collection changes.
class LocalDb {
  LocalDb._();
  static final instance = LocalDb._();

  final _changes = StreamController<String>.broadcast();

  /// All documents in [collection]; each map includes its 'id'.
  Stream<List<Map<String, dynamic>>> collectionSnapshots(
    String collection,
  ) async* {
    yield await getAll(collection);
    yield* _changes.stream
        .where((c) => c == collection)
        .asyncMap((_) => getAll(collection));
  }

  /// One document, or null if it doesn't exist (yet).
  Stream<Map<String, dynamic>?> docSnapshots(String collection, String id) =>
      collectionSnapshots(collection).map((docs) {
        for (final d in docs) {
          if (d['id'] == id) return d;
        }
        return null;
      });

  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final docs = await _load(collection);
    return docs.entries.map((e) => {...e.value, 'id': e.key}).toList();
  }

  /// Adds a document with a generated id and returns the id.
  Future<String> add(String collection, Map<String, dynamic> data) async {
    final id = const Uuid().v4();
    await set(collection, id, data);
    return id;
  }

  Future<void> set(
    String collection,
    String id,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final docs = await _load(collection);
    docs[id] = merge ? {...?docs[id], ...data} : data;
    await _save(collection, docs);
  }

  Future<void> delete(String collection, String id) async {
    final docs = await _load(collection);
    docs.remove(id);
    await _save(collection, docs);
  }

  Future<Map<String, Map<String, dynamic>>> _load(String collection) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('db_$collection');
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
  }

  Future<void> _save(
    String collection,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_$collection', jsonEncode(docs));
    _changes.add(collection);
  }
}
