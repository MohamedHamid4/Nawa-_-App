import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/services/cloudinary_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_block.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/local/local_datasource.dart';
import '../datasources/remote/firestore_remote_datasource.dart';
import '../models/pending_op.dart';

class NoteRepositoryImpl implements NoteRepository {
  final LocalDatasource _local;
  final FirestoreRemoteDatasource _remote;
  final ConnectivityService _connectivity;
  final CloudinaryStorageService _cloudinary;

  final _streamController = StreamController<List<Note>>.broadcast();
  StreamSubscription<List<Note>>? _remoteSub;
  String? _lastUid;
  bool _flushing = false;
  static const _uuid = Uuid();

  NoteRepositoryImpl({
    required LocalDatasource local,
    required FirestoreRemoteDatasource remote,
    required ConnectivityService connectivity,
    required CloudinaryStorageService cloudinary,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity,
        _cloudinary = cloudinary;

  @override
  Stream<List<Note>> watchNotes(String userId) {
    _attachRemoteIfNeeded(userId);
    Future.microtask(() => _emitLocal(userId));
    return _streamController.stream;
  }

  void _attachRemoteIfNeeded(String userId) {
    if (_lastUid == userId && _remoteSub != null) return;
    _lastUid = userId;
    _remoteSub?.cancel();
    _remoteSub = _remote.watchNotes(userId).listen((remote) async {
      // merge by updatedAt (last write wins)
      for (final r in remote) {
        final local = _local.getNote(r.id);
        if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
          await _local.putNote(r);
        }
      }
      _emitLocal(userId);
    }, onError: (e, st) {
      AppLogger.w('remote notes error: $e');
    });
  }

  void _emitLocal(String uid) {
    final list = _local.getAllNotes(uid);
    if (!_streamController.isClosed) {
      _streamController.add(list);
    }
  }

  @override
  Future<Result<Note?>> getNote(String id) async {
    try {
      return Success(_local.getNote(id));
    } catch (e) {
      return FailureResult(CacheFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> saveNote(Note note) async {
    try {
      await _local.putNote(note);
      final op = PendingOp(
        id: _uuid.v4(),
        userId: note.userId,
        noteId: note.id,
        kind: PendingOpKind.upsert,
        snapshot: note.toMap(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _local.enqueueOp(op);
      _emitLocal(note.userId);
      unawaited(_tryFlush());
      return const Success(null);
    } catch (e, st) {
      AppLogger.e('saveNote', e, st);
      return FailureResult(CacheFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> deleteNote(String id) async {
    try {
      final note = _local.getNote(id);
      if (note == null) return const Success(null);
      await _local.markNoteDeleted(id);
      final op = PendingOp(
        id: _uuid.v4(),
        userId: note.userId,
        noteId: id,
        kind: PendingOpKind.delete,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _local.enqueueOp(op);
      _emitLocal(note.userId);
      unawaited(_tryFlush());
      return const Success(null);
    } catch (e, st) {
      AppLogger.e('deleteNote', e, st);
      return FailureResult(CacheFailure(cause: e));
    }
  }

  @override
  Future<Result<List<Note>>> search(String query) async {
    try {
      final uid = _lastUid;
      if (uid == null) return const Success([]);
      final all = _local.getAllNotes(uid);
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return Success(all);
      final filtered = all
          .where((n) => n.plainTextSearchable.contains(q))
          .toList();
      return Success(filtered);
    } catch (e) {
      return FailureResult(CacheFailure(cause: e));
    }
  }

  @override
  Future<Result<void>> wipeUser(String uid) async {
    try {
      await _local.wipeUser(uid);
      _emitLocal(uid);
      return const Success(null);
    } catch (e) {
      return FailureResult(CacheFailure(cause: e));
    }
  }

  @override
  int pendingOpsCount() => _local.pendingCount();

  @override
  Future<void> flushPending() => _tryFlush();

  Future<Note> _uploadAttachments(Note note) async {
    final updatedBlocks = <NoteBlock>[];
    var changed = false;
    for (final block in note.blocks) {
      String? newUrl;
      if (block is ImageBlock &&
          block.localPath != null &&
          (block.remoteUrl == null || block.remoteUrl!.isEmpty)) {
        newUrl = await _cloudinary.upload(
          localPath: block.localPath!,
          userId: note.userId,
          noteId: note.id,
          blockId: block.id,
        );
        if (newUrl != null) {
          updatedBlocks.add(block.copyWith(remoteUrl: newUrl));
          changed = true;
          continue;
        }
      } else if (block is VideoBlock &&
          block.localPath != null &&
          (block.remoteUrl == null || block.remoteUrl!.isEmpty)) {
        newUrl = await _cloudinary.upload(
          localPath: block.localPath!,
          userId: note.userId,
          noteId: note.id,
          blockId: block.id,
        );
        if (newUrl != null) {
          updatedBlocks.add(block.copyWith(remoteUrl: newUrl));
          changed = true;
          continue;
        }
      } else if (block is AudioBlock &&
          block.localPath != null &&
          (block.remoteUrl == null || block.remoteUrl!.isEmpty)) {
        newUrl = await _cloudinary.upload(
          localPath: block.localPath!,
          userId: note.userId,
          noteId: note.id,
          blockId: block.id,
        );
        if (newUrl != null) {
          updatedBlocks.add(block.copyWith(remoteUrl: newUrl));
          changed = true;
          continue;
        }
      } else if (block is FileBlock &&
          block.localPath != null &&
          (block.remoteUrl == null || block.remoteUrl!.isEmpty)) {
        newUrl = await _cloudinary.upload(
          localPath: block.localPath!,
          userId: note.userId,
          noteId: note.id,
          blockId: block.id,
        );
        if (newUrl != null) {
          updatedBlocks.add(block.copyWith(remoteUrl: newUrl));
          changed = true;
          continue;
        }
      }
      updatedBlocks.add(block);
    }
    return changed ? note.copyWith(blocks: updatedBlocks) : note;
  }

  Future<void> _tryFlush() async {
    if (_flushing) return;
    if (!_connectivity.isOnline) return;
    _flushing = true;
    try {
      final ops = _local.allPendingOps();
      if (ops.isEmpty) return;
      try {
        // Process upsert ops one-by-one so we can upload attachments first.
        // Delete ops are batched at the end.
        final deletes = <PendingOp>[];
        for (final op in ops) {
          if (op.kind == PendingOpKind.delete) {
            deletes.add(op);
            continue;
          }
          if (op.snapshot == null) {
            await _local.removeOp(op.id);
            continue;
          }
          final note = Note.fromMap(Map<String, dynamic>.from(op.snapshot!));
          final synced = await _uploadAttachments(note);
          await _remote.upsertNote(synced);
          if (!identical(synced, note)) {
            await _local.putNote(synced);
          }
          await _local.removeOp(op.id);
        }
        if (deletes.isNotEmpty) {
          await _remote.commitOpsBatch(deletes);
          for (final op in deletes) {
            await _local.removeOp(op.id);
          }
        }
      } catch (e) {
        AppLogger.w('flush failed: $e');
        for (final op in ops.take(20)) {
          await _local.updateOp(op.incrementAttempts());
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> dispose() async {
    await _remoteSub?.cancel();
    await _streamController.close();
  }
}
