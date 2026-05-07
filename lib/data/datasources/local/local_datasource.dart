import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/user.dart';
import '../../models/pending_op.dart';

class LocalDatasource {
  late Box<dynamic> _notes;
  late Box<dynamic> _ops;
  late Box<dynamic> _cache;

  Future<void> init() async {
    await Hive.initFlutter();
    _notes = await Hive.openBox<dynamic>(HiveBoxes.notes);
    _ops = await Hive.openBox<dynamic>(HiveBoxes.pendingOps);
    _cache = await Hive.openBox<dynamic>(HiveBoxes.cache);
  }

  // ─── Notes ───────────────────────────────────────────────
  List<Note> getAllNotes(String uid) {
    final result = <Note>[];
    for (final key in _notes.keys) {
      final raw = _notes.get(key);
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        if ((m['userId'] as String?) != uid) continue;
        if ((m['deleted'] as bool?) == true) continue;
        result.add(Note.fromMap(m));
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Note? getNote(String id) {
    final raw = _notes.get(id);
    if (raw is Map) {
      return Note.fromMap(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> putNote(Note note) async {
    await _notes.put(note.id, note.toMap());
  }

  Future<void> markNoteDeleted(String id) async {
    final raw = _notes.get(id);
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      m['deleted'] = true;
      m['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _notes.put(id, m);
    }
  }

  Future<void> hardDeleteNote(String id) async {
    await _notes.delete(id);
  }

  Future<void> wipeUser(String uid) async {
    final keysToDelete = <dynamic>[];
    for (final key in _notes.keys) {
      final raw = _notes.get(key);
      if (raw is Map && (raw['userId'] as String?) == uid) {
        keysToDelete.add(key);
      }
    }
    await _notes.deleteAll(keysToDelete);

    final opsKeys = <dynamic>[];
    for (final key in _ops.keys) {
      final raw = _ops.get(key);
      if (raw is Map && (raw['userId'] as String?) == uid) {
        opsKeys.add(key);
      }
    }
    await _ops.deleteAll(opsKeys);

    final cacheKeys = <dynamic>[];
    for (final key in _cache.keys) {
      final k = '$key';
      if (k.startsWith('user:$uid:') || k.startsWith('workspaces:$uid')) {
        cacheKeys.add(key);
      }
    }
    await _cache.deleteAll(cacheKeys);
  }

  // ─── Pending ops ─────────────────────────────────────────
  List<PendingOp> allPendingOps() {
    final list = <PendingOp>[];
    for (final key in _ops.keys) {
      final raw = _ops.get(key);
      if (raw is Map) {
        list.add(PendingOp.fromMap(Map<String, dynamic>.from(raw)));
      }
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> enqueueOp(PendingOp op) async {
    await _ops.put(op.id, op.toMap());
  }

  Future<void> updateOp(PendingOp op) async {
    await _ops.put(op.id, op.toMap());
  }

  Future<void> removeOp(String id) async {
    await _ops.delete(id);
  }

  int pendingCount() => _ops.length;

  // ─── Cache (workspaces, simple maps) ─────────────────────
  Future<void> putRaw(String key, Map<String, dynamic> value) async {
    await _cache.put(key, value);
  }

  Map<String, dynamic>? getRaw(String key) {
    final raw = _cache.get(key);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> putRawList(String key, List<Map<String, dynamic>> value) async {
    await _cache.put(key, value);
  }

  List<Map<String, dynamic>>? getRawList(String key) {
    final raw = _cache.get(key);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return null;
  }

  Future<void> deleteCacheKey(String key) => _cache.delete(key);

  Future<void> clearCacheBox() async {
    await _cache.clear();
  }

  // ─── Workspaces ──────────────────────────────────────────
  String _wsKey(String uid) => 'workspaces:$uid';

  List<Workspace> getWorkspaces(String uid) {
    final list = getRawList(_wsKey(uid)) ?? [];
    return list.map((m) => Workspace.fromMap(m)).toList();
  }

  Future<void> setWorkspaces(String uid, List<Workspace> ws) async {
    await putRawList(_wsKey(uid), ws.map((e) => e.toMap()).toList());
  }
}
